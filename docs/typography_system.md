# Typography System

This app uses a small, consistent typography scale for readability and clean hierarchy.

## Roles and Tokens

1. `Screen Title` (AppBar title)
   - Token: `textTheme.titleLarge`
   - Size/weight: `21sp / w700`

2. `Section Title` (e.g. "Aktivitas hari ini", "Progres mingguan")
   - Token: `textTheme.titleMedium` (or `titleSmall` for tighter sections)
   - Size/weight: `17sp / w600` (`16sp / w600` for `titleSmall`)

3. `Primary Numbers` (e.g. `0/1`, `0 hari`, `75%`)
   - Token: `textTheme.headlineSmall` (or `headlineMedium` for the largest number on a screen)
   - Size/weight: `24sp / w700` (`28sp / w700` for `headlineMedium`)
   - Rule: Always visually larger than nearby title/body text.

4. `Body Text` (descriptions, helper text)
   - Token: `textTheme.bodyLarge` or `textTheme.bodyMedium`
   - Size/weight: `16sp / w400` or `14sp / w400`

5. `Secondary Info` (date/time details, helper metadata)
   - Token: `textTheme.bodySmall` or `textTheme.labelSmall`
   - Size/weight/color: `13sp / w400` or `12sp / w500`, gray (`secondaryText`)

6. `Button Text`
   - Token: `textTheme.labelLarge` (or `labelMedium` for compact)
   - Size/weight: `15sp / w500` (`14sp / w500`)

## Guardrails

- Avoid hardcoded `fontSize` in feature pages. Keep typography sizing in theme.
- Avoid `FontWeight.w800/w900` in feature pages.
- Avoid flattening hierarchy by not keeping titles and secondary info at similar size/weight.
- Use semantic colors only for meaning (status/urgency), not decoration.

Automated checks are in `test/typography_guardrails_test.dart`.
