package flutter.overlay.window.flutter_overlay_window;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.content.res.Configuration;
import android.content.res.Resources;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.PixelFormat;
import android.app.PendingIntent;
import android.graphics.Point;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.util.DisplayMetrics;
import android.util.Log;
import android.util.TypedValue;
import android.view.Display;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowManager;
import android.animation.ValueAnimator;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.view.HapticFeedbackConstants;
import android.view.animation.DecelerateInterpolator;
import android.widget.FrameLayout;
import android.widget.TextView;

import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.core.app.NotificationCompat;

import java.util.HashMap;
import java.util.Map;
import java.util.Timer;
import java.util.TimerTask;

import io.flutter.embedding.android.FlutterTextureView;
import io.flutter.embedding.android.FlutterView;
import io.flutter.FlutterInjector;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.embedding.engine.FlutterEngineGroup;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.JSONMessageCodec;
import io.flutter.plugin.common.MethodChannel;

public class OverlayService extends Service implements View.OnTouchListener {
    private final int DEFAULT_NAV_BAR_HEIGHT_DP = 48;
    private final int DEFAULT_STATUS_BAR_HEIGHT_DP = 25;

    private Integer mStatusBarHeight = -1;
    private Integer mNavigationBarHeight = -1;
    private Resources mResources;

    public static final String INTENT_EXTRA_IS_CLOSE_WINDOW = "IsCloseWindow";
    public static final String ACTION_TOGGLE_OR_SHOW_OVERLAY = "flutter.overlay.window.ACTION_TOGGLE_OR_SHOW";
    public static final String ACTION_RESTORE_NOTIFICATION = "flutter.overlay.window.ACTION_RESTORE_NOTIFICATION";
    public static final String SILENT_CHANNEL_ID = "nousen_assist_silent_channel";

    private static OverlayService instance;
    public static boolean isRunning = false;
    private WindowManager windowManager = null;
    private FlutterView flutterView;
    private MethodChannel flutterChannel;
    private BasicMessageChannel<Object> overlayMessageChannel;
    private int clickableFlag = WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE | WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE |
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS | WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN;

    private Handler mAnimationHandler = new Handler();
    private float lastX, lastY;
    private int lastYPosition;
    private boolean dragging;
    private static final float MAXIMUM_OPACITY_ALLOWED_FOR_S_AND_HIGHER = 0.8f;
    private Point szWindow = new Point();
    private ValueAnimator mSnapAnimator;

    private boolean isViewAttached = false;
    private DismissTargetView dismissView;
    private WindowManager.LayoutParams dismissParams;
    private boolean isDismissViewAttached = false;
    private static final int MAGNETIC_SNAP_RADIUS_DP = 40;
    private boolean isMagneticallySnapped = false;
    private int preMagnetX = 0;
    private int preMagnetY = 0;

    private boolean wasNearDismiss = false;
    private boolean wasTouchingDismiss = false;
    private WindowManager.LayoutParams mOverlayParams;
    private int savedBubbleX = 0;
    private int savedBubbleY = 0;
    private boolean hasSavedBubblePosition = false;

    private class DismissTargetView extends View {
        private final Paint bgPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Paint borderPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Paint xPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private boolean isTargetActive = false;

        public DismissTargetView(Context context) {
            super(context);
            setElevation(0f);
            setTranslationZ(0f);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                setOutlineProvider(null);
                setStateListAnimator(null);
            }

            bgPaint.setStyle(Paint.Style.FILL);
            bgPaint.setColor(Color.parseColor("#CC0F172A"));

            borderPaint.setStyle(Paint.Style.STROKE);
            borderPaint.setColor(Color.WHITE);
            borderPaint.setStrokeWidth(dpToPx(1.8f));

            xPaint.setStyle(Paint.Style.STROKE);
            xPaint.setColor(Color.WHITE);
            xPaint.setStrokeWidth(dpToPx(2.6f));
            xPaint.setStrokeCap(Paint.Cap.ROUND);
        }

        public void setActive(boolean active) {
            this.isTargetActive = active;
        }

        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            float cx = getWidth() / 2.0f;
            float cy = getHeight() / 2.0f;
            float radius = (Math.min(getWidth(), getHeight()) / 2.0f) - dpToPx(3);

            // 1. Draw solid circle
            canvas.drawCircle(cx, cy, radius, bgPaint);
            // 2. Draw crisp border
            canvas.drawCircle(cx, cy, radius, borderPaint);

            // 3. Draw clean '✕' (zero font shadow, zero elevation shadow)
            float arm = radius * 0.38f;
            canvas.drawLine(cx - arm, cy - arm, cx + arm, cy + arm, xPaint);
            canvas.drawLine(cx - arm, cy + arm, cx + arm, cy - arm, xPaint);
        }
    }

    private void cancelSnapAnimation() {
        if (mSnapAnimator != null) {
            mSnapAnimator.cancel();
            mSnapAnimator = null;
        }
    }

    private void initDismissView() {
        if (dismissView != null) return;
        dismissView = new DismissTargetView(this);

        int size = dpToPx(56);
        dismissParams = new WindowManager.LayoutParams(
                size,
                size,
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.O ? WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY : WindowManager.LayoutParams.TYPE_PHONE,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                        | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
                        | WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
                        | WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
                        | WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
                PixelFormat.TRANSLUCENT
        );
        dismissParams.gravity = Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL;
        dismissParams.y = dpToPx(38);
        dismissParams.windowAnimations = 0;
    }

    private void showDismissTarget(boolean nearDismiss) {
        initDismissView();
        if (windowManager == null || dismissView == null) return;
        if (!isDismissViewAttached) {
            try {
                dismissView.setScaleX(0f);
                dismissView.setScaleY(0f);
                dismissView.setAlpha(0f);
                windowManager.addView(dismissView, dismissParams);
                isDismissViewAttached = true;
                // Smooth appear animation
                dismissView.animate()
                    .scaleX(1f).scaleY(1f).alpha(1f)
                    .setDuration(180)
                    .setInterpolator(new DecelerateInterpolator())
                    .start();
            } catch (Exception ignored) {}
        }
        if (nearDismiss != wasNearDismiss) {
            wasNearDismiss = nearDismiss;
            dismissView.setActive(nearDismiss);
            // Pulse scale on magnetic snap
            float targetScale = nearDismiss ? 1.15f : 1.0f;
            dismissView.animate()
                .scaleX(targetScale).scaleY(targetScale)
                .setDuration(120)
                .setInterpolator(new DecelerateInterpolator())
                .start();
            if (nearDismiss && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                dismissView.performHapticFeedback(HapticFeedbackConstants.CONTEXT_CLICK);
            }
        }
    }

    private void hideDismissTarget() {
        wasNearDismiss = false;
        if (dismissView != null) {
            dismissView.setActive(false);
        }
        if (windowManager != null && dismissView != null && isDismissViewAttached) {
            // Smooth disappear animation before removing view
            dismissView.animate()
                .scaleX(0f).scaleY(0f).alpha(0f)
                .setDuration(140)
                .setInterpolator(new DecelerateInterpolator())
                .withEndAction(() -> {
                    if (windowManager != null && dismissView != null && isDismissViewAttached) {
                        try {
                            windowManager.removeView(dismissView);
                        } catch (Exception ignored) {}
                        isDismissViewAttached = false;
                    }
                })
                .start();
        }
    }

    private void hideOverlay() {
        cancelSnapAnimation();
        hideDismissTarget();
        if (overlayMessageChannel != null) {
            overlayMessageChannel.send("{\"type\":\"drag_near_dismiss\",\"isNear\":false}");
            overlayMessageChannel.send("{\"type\":\"reset_state\"}");
        }
        if (windowManager != null && flutterView != null && isViewAttached) {
            try {
                windowManager.removeView(flutterView);
            } catch (Exception ignored) {}
            isViewAttached = false;
        }
        updateNotification("Ketuk untuk memunculkan kembali bubble asisten");
    }

    private void showOverlayView() {
        if (overlayMessageChannel != null) {
            overlayMessageChannel.send("{\"type\":\"drag_near_dismiss\",\"isNear\":false}");
            overlayMessageChannel.send("{\"type\":\"reset_state\"}");
        }
        if (windowManager != null && flutterView != null && !isViewAttached) {
            if (mOverlayParams == null) {
                int layoutW = dpToPx(58);
                int layoutH = dpToPx(58);
                mOverlayParams = new WindowManager.LayoutParams(
                        layoutW,
                        layoutH,
                        0,
                        0,
                        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O ? WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY : WindowManager.LayoutParams.TYPE_PHONE,
                        WindowSetup.flag | WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
                                | WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
                                | WindowManager.LayoutParams.FLAG_LAYOUT_INSET_DECOR
                                | WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
                        PixelFormat.TRANSLUCENT
                );
                mOverlayParams.gravity = WindowSetup.gravity;
                mOverlayParams.windowAnimations = 0;
            }
            // Reset to initial position (right-center: x=0, y=0 with CENTER|RIGHT gravity)
            mOverlayParams.x = 0;
            mOverlayParams.y = 0;
            try {
                windowManager.addView(flutterView, mOverlayParams);
                isViewAttached = true;
            } catch (Exception ignored) {}
            snapToEdge();
        }
        updateNotification("Ketuk untuk membuka asisten aktivitas");
    }

    private Notification buildServiceNotification(String contentText) {
        Intent toggleIntent = new Intent(this, OverlayService.class);
        toggleIntent.setAction(ACTION_TOGGLE_OR_SHOW_OVERLAY);
        int pendingFlags = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ? PendingIntent.FLAG_IMMUTABLE : PendingIntent.FLAG_UPDATE_CURRENT;
        PendingIntent pendingIntent = PendingIntent.getService(this, 101, toggleIntent, pendingFlags);

        Intent deleteIntent = new Intent(this, OverlayService.class);
        deleteIntent.setAction(ACTION_RESTORE_NOTIFICATION);
        PendingIntent pendingDeleteIntent = PendingIntent.getService(this, 102, deleteIntent, pendingFlags);

        final int notifyIcon = getDrawableResourceId("mipmap", "launcher");
        Notification notification = new NotificationCompat.Builder(this, SILENT_CHANNEL_ID)
                .setContentTitle(WindowSetup.overlayTitle != null && !WindowSetup.overlayTitle.isEmpty() ? WindowSetup.overlayTitle : "NOUSEN Assist")
                .setContentText(contentText)
                .setSmallIcon(notifyIcon == 0 ? R.drawable.notification_icon : notifyIcon)
                .setContentIntent(pendingIntent)
                .setDeleteIntent(pendingDeleteIntent)
                .setOngoing(true)
                .setAutoCancel(false)
                .setOnlyAlertOnce(true)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setCategory(NotificationCompat.CATEGORY_SERVICE)
                .setSilent(true)
                .setVisibility(WindowSetup.notificationVisibility)
                .build();
        notification.flags |= Notification.FLAG_ONGOING_EVENT | Notification.FLAG_NO_CLEAR | Notification.FLAG_FOREGROUND_SERVICE;
        return notification;
    }

    private void updateNotification(String contentText) {
        NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        if (notificationManager != null) {
            notificationManager.notify(OverlayConstants.NOTIFICATION_ID, buildServiceNotification(contentText));
        }
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    @Override
    public void onDestroy() {
        Log.d("OverLay", "Destroying the overlay window service");
        cancelSnapAnimation();
        hideDismissTarget();
        if (windowManager != null) {
            if (flutterView != null && isViewAttached) {
                try {
                    windowManager.removeView(flutterView);
                } catch (Exception ignored) {}
            }
            windowManager = null;
            if (flutterView != null) {
                flutterView.detachFromFlutterEngine();
                flutterView = null;
            }
        }
        isViewAttached = false;
        isRunning = false;
        NotificationManager notificationManager = (NotificationManager) getApplicationContext().getSystemService(Context.NOTIFICATION_SERVICE);
        if (notificationManager != null) {
            notificationManager.cancel(OverlayConstants.NOTIFICATION_ID);
        }
        instance = null;
    }

    @RequiresApi(api = Build.VERSION_CODES.JELLY_BEAN_MR1)
    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        mResources = getApplicationContext().getResources();
        if (intent != null) {
            if (ACTION_TOGGLE_OR_SHOW_OVERLAY.equals(intent.getAction())) {
                if (!isViewAttached) {
                    showOverlayView();
                } else {
                    if (overlayMessageChannel != null) {
                        overlayMessageChannel.send("{\"type\":\"request_expand\"}");
                    }
                }
                return START_STICKY;
            }

            if (ACTION_RESTORE_NOTIFICATION.equals(intent.getAction())) {
                updateNotification(!isViewAttached
                        ? "Ketuk untuk memunculkan kembali bubble asisten"
                        : (WindowSetup.overlayContent != null && !WindowSetup.overlayContent.isEmpty() ? WindowSetup.overlayContent : "Ketuk untuk membuka asisten aktivitas"));
                return START_STICKY;
            }

            boolean isCloseWindow = intent.getBooleanExtra(INTENT_EXTRA_IS_CLOSE_WINDOW, false);
            if (isCloseWindow) {
                onDestroy();
                stopSelf();
                return START_NOT_STICKY;
            }
        }

        if (windowManager != null && flutterView != null) {
            showOverlayView();
            return START_STICKY;
        }

        isRunning = true;
        Log.d("onStartCommand", "Service started");
        FlutterEngine engine = FlutterEngineCache.getInstance().get(OverlayConstants.CACHED_TAG);
        if (engine == null) {
            return START_STICKY;
        }
        engine.getLifecycleChannel().appIsResumed();
        flutterView = new FlutterView(getApplicationContext(), new FlutterTextureView(getApplicationContext()));
        flutterView.attachToFlutterEngine(engine);
        flutterView.setFitsSystemWindows(true);
        flutterView.setFocusable(true);
        flutterView.setFocusableInTouchMode(true);
        flutterView.setBackgroundColor(Color.TRANSPARENT);
        flutterChannel.setMethodCallHandler((call, result) -> {
            if (call.method.equals("updateFlag")) {
                String flag = call.argument("flag").toString();
                updateOverlayFlag(result, flag);
            } else if (call.method.equals("updateOverlayPosition")) {
                int x = call.<Integer>argument("x");
                int y = call.<Integer>argument("y");
                moveOverlay(x, y, result);
            } else if (call.method.equals("resizeOverlay")) {
                int width = call.argument("width");
                int height = call.argument("height");
                boolean enableDrag = call.argument("enableDrag");
                resizeOverlay(width, height, enableDrag, result);
            } else if (call.method.equals("openApp")) {
                try {
                    Intent launchIntent = getPackageManager().getLaunchIntentForPackage(getPackageName());
                    if (launchIntent != null) {
                        launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_CLEAR_TOP);
                        String activityId = call.argument("activityId");
                        if (activityId != null && !activityId.isEmpty()) {
                            launchIntent.putExtra("activityId", activityId);
                        }
                        startActivity(launchIntent);
                        result.success(true);
                        return;
                    }
                } catch (Exception e) {
                    Log.e("OverlayService", "Failed to launch main app: " + e.getMessage());
                }
                result.success(false);
            }
        });
        overlayMessageChannel.setMessageHandler((message, reply) -> {
            WindowSetup.messenger.send(message);
        });
        windowManager = (WindowManager) getSystemService(WINDOW_SERVICE);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
            windowManager.getDefaultDisplay().getSize(szWindow);
        } else {
            DisplayMetrics displaymetrics = new DisplayMetrics();
            windowManager.getDefaultDisplay().getMetrics(displaymetrics);
            int w = displaymetrics.widthPixels;
            int h = displaymetrics.heightPixels;
            szWindow.set(w, h);
        }
        int startX = intent != null ? intent.getIntExtra("startX", OverlayConstants.DEFAULT_XY) : OverlayConstants.DEFAULT_XY;
        int startY = intent != null ? intent.getIntExtra("startY", OverlayConstants.DEFAULT_XY) : OverlayConstants.DEFAULT_XY;
        int layoutW = (WindowSetup.width == -1999 || WindowSetup.width == -1) ? -1 : dpToPx(WindowSetup.width);
        int layoutH = (WindowSetup.height == -1999 || WindowSetup.height == -1) ? screenHeight() : dpToPx(WindowSetup.height);
        mOverlayParams = new WindowManager.LayoutParams(
                layoutW,
                layoutH,
                0,
                0,
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.O ? WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY : WindowManager.LayoutParams.TYPE_PHONE,
                WindowSetup.flag | WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
                        | WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
                        | WindowManager.LayoutParams.FLAG_LAYOUT_INSET_DECOR
                        | WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
                PixelFormat.TRANSLUCENT
        );
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && WindowSetup.flag == clickableFlag) {
            mOverlayParams.alpha = MAXIMUM_OPACITY_ALLOWED_FOR_S_AND_HIGHER;
        }
        mOverlayParams.gravity = WindowSetup.gravity;
        mOverlayParams.windowAnimations = 0;
        flutterView.setOnTouchListener(this);
        flutterView.setHapticFeedbackEnabled(false);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            flutterView.setPointerIcon(android.view.PointerIcon.getSystemIcon(this, android.view.PointerIcon.TYPE_NULL));
        }
        try {
            windowManager.addView(flutterView, mOverlayParams);
            isViewAttached = true;
        } catch (Exception ignored) {}

        if (startX != OverlayConstants.DEFAULT_XY || startY != OverlayConstants.DEFAULT_XY) {
            int dx = startX == OverlayConstants.DEFAULT_XY ? 0 : startX;
            int dy = startY == OverlayConstants.DEFAULT_XY ? 0 : startY;
            moveOverlay(dx, dy, null);
        }

        createNotificationChannel();
        updateNotification(WindowSetup.overlayContent != null && !WindowSetup.overlayContent.isEmpty() ? WindowSetup.overlayContent : "Ketuk untuk membuka asisten aktivitas");
        return START_STICKY;
    }


    @RequiresApi(api = Build.VERSION_CODES.JELLY_BEAN_MR1)
    private int screenHeight() {
        Display display = windowManager.getDefaultDisplay();
        DisplayMetrics dm = new DisplayMetrics();
        display.getRealMetrics(dm);
        return inPortrait() ?
                dm.heightPixels + statusBarHeightPx() + navigationBarHeightPx()
                :
                dm.heightPixels + statusBarHeightPx();
    }

    private int statusBarHeightPx() {
        if (mStatusBarHeight == -1) {
            int statusBarHeightId = mResources.getIdentifier("status_bar_height", "dimen", "android");

            if (statusBarHeightId > 0) {
                mStatusBarHeight = mResources.getDimensionPixelSize(statusBarHeightId);
            } else {
                mStatusBarHeight = dpToPx(DEFAULT_STATUS_BAR_HEIGHT_DP);
            }
        }

        return mStatusBarHeight;
    }

    int navigationBarHeightPx() {
        if (mNavigationBarHeight == -1) {
            int navBarHeightId = mResources.getIdentifier("navigation_bar_height", "dimen", "android");

            if (navBarHeightId > 0) {
                mNavigationBarHeight = mResources.getDimensionPixelSize(navBarHeightId);
            } else {
                mNavigationBarHeight = dpToPx(DEFAULT_NAV_BAR_HEIGHT_DP);
            }
        }

        return mNavigationBarHeight;
    }


    private void updateOverlayFlag(MethodChannel.Result result, String flag) {
        if (windowManager != null) {
            WindowSetup.setFlag(flag);
            WindowManager.LayoutParams params = (WindowManager.LayoutParams) flutterView.getLayoutParams();
            params.flags = WindowSetup.flag | WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS |
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN |
                    WindowManager.LayoutParams.FLAG_LAYOUT_INSET_DECOR | WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && WindowSetup.flag == clickableFlag) {
                params.alpha = MAXIMUM_OPACITY_ALLOWED_FOR_S_AND_HIGHER;
            } else {
                params.alpha = 1;
            }
            windowManager.updateViewLayout(flutterView, params);
            result.success(true);
        } else {
            result.success(false);
        }
    }

    private void resizeOverlay(int width, int height, boolean enableDrag, MethodChannel.Result result) {
        if (windowManager != null && flutterView != null) {
            cancelSnapAnimation();
            WindowManager.LayoutParams params = (WindowManager.LayoutParams) flutterView.getLayoutParams();
            params.windowAnimations = 0;
            params.width = (width == -1999 || width == -1) ? -1 : dpToPx(width);
            params.height = (height == -1999 || height == -1) ? -1 : dpToPx(height);
            WindowSetup.enableDrag = enableDrag;

            boolean isCardSize = (height > 100 || height == -1 || height == -1999);
            boolean isCollapsingToBubble = enableDrag && hasSavedBubblePosition && !isCardSize;
            boolean isExpandingToCard = !enableDrag && isCardSize;

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
                windowManager.getDefaultDisplay().getSize(szWindow);
            }
            int targetW = (width == -1999 || width == -1) ? szWindow.x : dpToPx(width);

            if (isExpandingToCard) {
                // Expanding to card: save bubble position and enable watch outside touch
                savedBubbleX = params.x;
                savedBubbleY = params.y;
                hasSavedBubblePosition = true;
                params.flags |= WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH;

                // Center horizontally on screen
                params.x = Math.max(0, (szWindow.x - targetW) / 2);
                // Center vertically
                params.y = 0;
            } else if (isCollapsingToBubble) {
                // Collapsing back to bubble: restore bubble position and disable watch outside touch
                params.flags &= ~WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH;
                if (hasSavedBubblePosition) {
                    params.x = savedBubbleX;
                    params.y = savedBubbleY;
                    hasSavedBubblePosition = false;
                }
            } else if (width > 58 && height <= 100) {
                // Speech bubble active: stay strictly anchored to current edge, DO NOT center X or Y
                int midX = szWindow.x / 2;
                if (params.x >= midX) {
                    // Bubble is on the left side: flush to left edge
                    params.x = Math.max(0, szWindow.x - targetW);
                } else {
                    // Bubble is on the right side: flush to right edge
                    params.x = 0;
                }
            } else if (width <= 58 && height <= 100) {
                // Speech bubble collapsed back to small bubble: keep edge anchor, apply alpha-hide
                int midX = szWindow.x / 2;
                if (params.x >= midX) {
                    params.x = Math.max(0, szWindow.x - targetW);
                } else {
                    params.x = 0;
                }
            }

            boolean needsAlphaHide = isCollapsingToBubble || isExpandingToCard || (width <= 58 && height <= 100 && !isCollapsingToBubble);

            if (needsAlphaHide) {
                // Hide window at compositor level during reposition to avoid Mali gralloc buffer stretch artifact
                final float originalAlpha = (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && WindowSetup.flag == clickableFlag)
                        ? MAXIMUM_OPACITY_ALLOWED_FOR_S_AND_HIGHER : 1.0f;
                params.alpha = 0f;
                windowManager.updateViewLayout(flutterView, params);

                // Reveal window after SurfaceFlinger and WindowManager settle at target position
                flutterView.postDelayed(() -> {
                    if (windowManager != null && flutterView != null) {
                        try {
                            WindowManager.LayoutParams p = (WindowManager.LayoutParams) flutterView.getLayoutParams();
                            p.alpha = originalAlpha;
                            p.windowAnimations = 0;
                            windowManager.updateViewLayout(flutterView, p);
                        } catch (Exception ignored) {}
                    }
                }, 110);
            } else {
                windowManager.updateViewLayout(flutterView, params);
            }
            result.success(true);
        } else {
            result.success(false);
        }
    }

    private void moveOverlay(int x, int y, MethodChannel.Result result) {
        if (windowManager != null) {
            WindowManager.LayoutParams params = (WindowManager.LayoutParams) flutterView.getLayoutParams();
            params.x = (x == -1999 || x == -1) ? -1 : dpToPx(x);
            params.y = dpToPx(y);
            windowManager.updateViewLayout(flutterView, params);
            if (result != null)
                result.success(true);
        } else {
            if (result != null)
                result.success(false);
        }
    }


    public static Map<String, Double> getCurrentPosition() {
        if (instance != null && instance.flutterView != null) {
            WindowManager.LayoutParams params = (WindowManager.LayoutParams) instance.flutterView.getLayoutParams();
            Map<String, Double> position = new HashMap<>();
            position.put("x", instance.pxToDp(params.x));
            position.put("y", instance.pxToDp(params.y));
            return position;
        }
        return null;
    }

    public static boolean moveOverlay(int x, int y) {
        if (instance != null && instance.flutterView != null) {
            if (instance.windowManager != null) {
                WindowManager.LayoutParams params = (WindowManager.LayoutParams) instance.flutterView.getLayoutParams();
                params.x = (x == -1999 || x == -1) ? -1 : instance.dpToPx(x);
                params.y = instance.dpToPx(y);
                instance.windowManager.updateViewLayout(instance.flutterView, params);
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }


    @Override
    public void onCreate() {
        // Get the cached FlutterEngine
        FlutterEngine flutterEngine = FlutterEngineCache.getInstance().get(OverlayConstants.CACHED_TAG);

        if (flutterEngine == null) {
            // Handle the error if engine is not found
            Log.e("OverlayService", "Flutter engine not found, hence creating new flutter engine");
            FlutterEngineGroup engineGroup = new FlutterEngineGroup(this);
            DartExecutor.DartEntrypoint entryPoint = new DartExecutor.DartEntrypoint(
                FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                "overlayMain"
            );  // "overlayMain" is custom entry point

            flutterEngine = engineGroup.createAndRunEngine(this, entryPoint);

            // Cache the created FlutterEngine for future use
            FlutterEngineCache.getInstance().put(OverlayConstants.CACHED_TAG, flutterEngine);
        }

        // Create the MethodChannel with the properly initialized FlutterEngine
        if (flutterEngine != null) {
            flutterChannel = new MethodChannel(flutterEngine.getDartExecutor(), OverlayConstants.OVERLAY_TAG);
            overlayMessageChannel = new BasicMessageChannel(flutterEngine.getDartExecutor(), OverlayConstants.MESSENGER_TAG, JSONMessageCodec.INSTANCE);
        }

        createNotificationChannel();
        startForeground(OverlayConstants.NOTIFICATION_ID, buildServiceNotification(WindowSetup.overlayContent != null && !WindowSetup.overlayContent.isEmpty() ? WindowSetup.overlayContent : "Ketuk untuk membuka asisten aktivitas"));
        instance = this;
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel serviceChannel = new NotificationChannel(
                    SILENT_CHANNEL_ID,
                    "NOUSEN Assist Shortcut",
                    NotificationManager.IMPORTANCE_LOW
            );
            serviceChannel.setDescription("Shortcut asisten aktivitas senyap");
            serviceChannel.setSound(null, null);
            serviceChannel.enableVibration(false);
            serviceChannel.setShowBadge(false);
            NotificationManager manager = getSystemService(NotificationManager.class);
            assert manager != null;
            manager.createNotificationChannel(serviceChannel);
        }
    }

    private int getDrawableResourceId(String resType, String name) {
        return getApplicationContext().getResources().getIdentifier(String.format("ic_%s", name), resType, getApplicationContext().getPackageName());
    }

    private int dpToPx(int dp) {
        return (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP,
                Float.parseFloat(dp + ""), mResources.getDisplayMetrics());
    }

    private float dpToPx(float dp) {
        return TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP,
                dp, mResources.getDisplayMetrics());
    }

    private double pxToDp(int px) {
        return (double) px / mResources.getDisplayMetrics().density;
    }

    private boolean inPortrait() {
        return mResources.getConfiguration().orientation == Configuration.ORIENTATION_PORTRAIT;
    }

    private int clampX(int x, int viewW) {
        if (windowManager != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
            windowManager.getDefaultDisplay().getSize(szWindow);
        }
        int effectiveW = viewW > 0 ? viewW : dpToPx(58);
        int padding = dpToPx(4);

        boolean isRightAligned = (WindowSetup.gravity & Gravity.HORIZONTAL_GRAVITY_MASK) == Gravity.RIGHT;
        boolean isCenterH = (WindowSetup.gravity & Gravity.HORIZONTAL_GRAVITY_MASK) == Gravity.CENTER_HORIZONTAL;

        if (isCenterH) {
            int half = szWindow.x / 2;
            int minX = -(half - padding);
            int maxX = half - effectiveW + padding;
            return Math.max(minX, Math.min(x, maxX));
        } else if (isRightAligned) {
            int minX = 0;
            int maxX = szWindow.x - effectiveW;
            return Math.max(minX, Math.min(x, maxX));
        } else {
            int minX = 0;
            int maxX = szWindow.x - effectiveW;
            return Math.max(minX, Math.min(x, maxX));
        }
    }

    private int clampY(int y, int viewH) {
        if (windowManager != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
            windowManager.getDefaultDisplay().getSize(szWindow);
        }
        int effectiveH = viewH > 0 ? viewH : dpToPx(58);
        int sb = statusBarHeightPx();
        int nb = navigationBarHeightPx();
        boolean isCentered = (WindowSetup.gravity & Gravity.VERTICAL_GRAVITY_MASK) == Gravity.CENTER_VERTICAL;
        boolean isBottom = (WindowSetup.gravity & Gravity.VERTICAL_GRAVITY_MASK) == Gravity.BOTTOM;

        if (isCentered) {
            int minY = - (szWindow.y / 2) + sb + dpToPx(16);
            int maxY = (szWindow.y / 2) - effectiveH - nb - dpToPx(16);
            return Math.max(minY, Math.min(y, maxY));
        } else if (isBottom) {
            int minY = dpToPx(16);
            int maxY = szWindow.y - effectiveH - sb - nb - dpToPx(16);
            return Math.max(minY, Math.min(y, maxY));
        } else {
            int minY = sb + dpToPx(16);
            int maxY = szWindow.y - effectiveH - nb - dpToPx(16);
            return Math.max(minY, Math.min(y, maxY));
        }
    }

    private void snapToEdge() {
        if (windowManager == null || flutterView == null) return;
        cancelSnapAnimation();

        WindowManager.LayoutParams params = (WindowManager.LayoutParams) flutterView.getLayoutParams();
        int viewW = flutterView.getWidth() > 0 ? flutterView.getWidth() : dpToPx(58);
        int viewH = flutterView.getHeight() > 0 ? flutterView.getHeight() : dpToPx(58);

        int startX = params.x;
        int targetX;

        boolean isRightAligned = (WindowSetup.gravity & Gravity.HORIZONTAL_GRAVITY_MASK) == Gravity.RIGHT;

        if (isRightAligned) {
            int midX = (szWindow.x - viewW) / 2;
            if (WindowSetup.positionGravity.equals("left")) {
                targetX = Math.max(0, szWindow.x - viewW);
            } else if (WindowSetup.positionGravity.equals("right")) {
                targetX = 0;
            } else {
                targetX = (startX >= midX) ? Math.max(0, szWindow.x - viewW) : 0;
            }
        } else {
            int midX = (szWindow.x - viewW) / 2;
            if (WindowSetup.positionGravity.equals("left")) {
                targetX = 0;
            } else if (WindowSetup.positionGravity.equals("right")) {
                targetX = Math.max(0, szWindow.x - viewW);
            } else {
                targetX = (startX >= midX) ? Math.max(0, szWindow.x - viewW) : 0;
            }
        }

        int startY = params.y;
        int targetY = clampY(startY, viewH);

        if (startX == targetX && startY == targetY) {
            return;
        }

        mSnapAnimator = ValueAnimator.ofFloat(0f, 1f);
        mSnapAnimator.setDuration(220);
        mSnapAnimator.setInterpolator(new DecelerateInterpolator());
        final int fStartX = startX;
        final int fTargetX = targetX;
        final int fStartY = startY;
        final int fTargetY = targetY;
        final int fMidX = (szWindow.x - viewW) / 2;
        final boolean fIsRightAligned = isRightAligned;
        mSnapAnimator.addUpdateListener(animation -> {
            if (windowManager == null || flutterView == null) return;
            float frac = animation.getAnimatedFraction();
            WindowManager.LayoutParams lp = (WindowManager.LayoutParams) flutterView.getLayoutParams();
            lp.x = (int) (fStartX + (fTargetX - fStartX) * frac);
            lp.y = (int) (fStartY + (fTargetY - fStartY) * frac);
            try {
                windowManager.updateViewLayout(flutterView, lp);
            } catch (Exception ignored) {}

            if (frac >= 1.0f && overlayMessageChannel != null) {
                // Determine which side bubble snapped to
                boolean isRight = fIsRightAligned ? (fTargetX <= fMidX) : (fTargetX >= fMidX);
                overlayMessageChannel.send("{\"type\":\"bubble_side\",\"side\":\"" + (isRight ? "right" : "left") + "\"}");
            }
        });
        mSnapAnimator.start();
    }

    @Override
    public boolean onTouch(View view, MotionEvent event) {
        if (windowManager != null && flutterView != null) {
            if (event.getAction() == MotionEvent.ACTION_OUTSIDE) {
                if (overlayMessageChannel != null) {
                    overlayMessageChannel.send("{\"type\":\"request_collapse\"}");
                }
                return false;
            }
            if (!WindowSetup.enableDrag) {
                return false;
            }
            WindowManager.LayoutParams params = (WindowManager.LayoutParams) flutterView.getLayoutParams();
            switch (event.getAction()) {
                case MotionEvent.ACTION_DOWN:
                    cancelSnapAnimation();
                    dragging = false;
                    lastX = event.getRawX();
                    lastY = event.getRawY();
                    break;
                case MotionEvent.ACTION_MOVE:
                    cancelSnapAnimation();
                    float dx = event.getRawX() - lastX;
                    float dy = event.getRawY() - lastY;
                    if (!dragging && dx * dx + dy * dy < 25) {
                        return false;
                    }
                    lastX = event.getRawX();
                    lastY = event.getRawY();
                    boolean invertX = WindowSetup.gravity == (Gravity.TOP | Gravity.RIGHT)
                            || WindowSetup.gravity == (Gravity.CENTER | Gravity.RIGHT)
                            || WindowSetup.gravity == (Gravity.BOTTOM | Gravity.RIGHT);
                    boolean invertY = WindowSetup.gravity == (Gravity.BOTTOM | Gravity.LEFT)
                            || WindowSetup.gravity == Gravity.BOTTOM
                            || WindowSetup.gravity == (Gravity.BOTTOM | Gravity.RIGHT);
                    int xx = params.x + ((int) dx * (invertX ? -1 : 1));
                    int yy = params.y + ((int) dy * (invertY ? -1 : 1));

                    int viewWidth = flutterView.getWidth();
                    int viewHeight = flutterView.getHeight();
                    xx = clampX(xx, viewWidth);
                    yy = clampY(yy, viewHeight);

                    params.x = xx;
                    params.y = yy;
                    try {
                        windowManager.updateViewLayout(flutterView, params);
                    } catch (Exception ignored) {}
                    dragging = true;

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
                        windowManager.getDefaultDisplay().getSize(szWindow);
                    }

                    int dismissSize = dpToPx(56);
                    float targetCenterX = szWindow.x / 2.0f;
                    float targetCenterY = szWindow.y - dpToPx(38) - (dismissSize / 2.0f);

                    int[] bubbleLoc = new int[2];
                    flutterView.getLocationOnScreen(bubbleLoc);
                    float bubbleCenterX = bubbleLoc[0] + (flutterView.getWidth() / 2.0f);
                    float bubbleCenterY = bubbleLoc[1] + (flutterView.getHeight() / 2.0f);

                    float dxTarget = bubbleCenterX - targetCenterX;
                    float dyTarget = bubbleCenterY - targetCenterY;
                    float distTarget = (float) Math.sqrt(dxTarget * dxTarget + dyTarget * dyTarget);
                    float magneticRadius = dpToPx(MAGNETIC_SNAP_RADIUS_DP);
                    boolean inMagneticZone = distTarget <= magneticRadius;

                    if (inMagneticZone && !isMagneticallySnapped) {
                        // Save pre-magnet position and snap bubble center onto ✕ center
                        preMagnetX = params.x;
                        preMagnetY = params.y;
                        isMagneticallySnapped = true;

                        // Calculate layout params that place bubble center at ✕ center
                        int bubbleW = flutterView.getWidth() > 0 ? flutterView.getWidth() : dpToPx(58);
                        int bubbleH = flutterView.getHeight() > 0 ? flutterView.getHeight() : dpToPx(58);
                        boolean snapInvertX = WindowSetup.gravity == (Gravity.TOP | Gravity.RIGHT)
                                || WindowSetup.gravity == (Gravity.CENTER | Gravity.RIGHT)
                                || WindowSetup.gravity == (Gravity.BOTTOM | Gravity.RIGHT);
                        boolean snapInvertY = WindowSetup.gravity == (Gravity.BOTTOM | Gravity.LEFT)
                                || WindowSetup.gravity == Gravity.BOTTOM
                                || WindowSetup.gravity == (Gravity.BOTTOM | Gravity.RIGHT);
                        int snapX, snapY;
                        if (snapInvertX) {
                            snapX = szWindow.x - (int) targetCenterX - bubbleW / 2;
                        } else {
                            snapX = (int) targetCenterX - bubbleW / 2;
                        }
                        if (snapInvertY) {
                            snapY = szWindow.y - (int) targetCenterY - bubbleH / 2;
                        } else {
                            snapY = (int) targetCenterY - bubbleH / 2;
                        }
                        params.x = snapX;
                        params.y = snapY;
                        try {
                            windowManager.updateViewLayout(flutterView, params);
                        } catch (Exception ignored) {}

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && dismissView != null) {
                            dismissView.performHapticFeedback(HapticFeedbackConstants.CONTEXT_CLICK);
                        }
                    } else if (!inMagneticZone && isMagneticallySnapped) {
                        // Exited magnetic zone — release snap
                        isMagneticallySnapped = false;
                    }

                    boolean isTouchingDismiss = isMagneticallySnapped;
                    wasTouchingDismiss = isTouchingDismiss;

                    boolean inLowerArea = bubbleCenterY >= (szWindow.y * 0.65f);
                    if (inLowerArea || isTouchingDismiss) {
                        showDismissTarget(isTouchingDismiss);
                    } else {
                        hideDismissTarget();
                    }

                    if (overlayMessageChannel != null) {
                        overlayMessageChannel.send("{\"type\":\"drag_near_dismiss\",\"isNear\":" + isTouchingDismiss + "}");
                    }
                    break;
                case MotionEvent.ACTION_UP:
                case MotionEvent.ACTION_CANCEL:
                    boolean wasMagneticallySnapped = isMagneticallySnapped;
                    isMagneticallySnapped = false;
                    wasTouchingDismiss = false;
                    hideDismissTarget();

                    if (overlayMessageChannel != null) {
                        overlayMessageChannel.send("{\"type\":\"drag_near_dismiss\",\"isNear\":false}");
                    }

                    if (wasMagneticallySnapped) {
                        if (overlayMessageChannel != null) {
                            overlayMessageChannel.send("{\"type\":\"overlay_dismissed_by_user\"}");
                        }
                        hideOverlay();
                        return false;
                    }

                    if (!WindowSetup.positionGravity.equals("none")) {
                        snapToEdge();
                    }
                    return false;
                default:
                    return false;
            }
            return false;
        }
        return false;
    }


}