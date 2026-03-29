# StillMac — Launch Checklist

## Pre-Submission

### Code & Build
- [x] Build succeeds in Release configuration (`xcodebuild -scheme StillMac -configuration Release`)
- [x] No hardcoded colors — all colors use `Theme.*` tokens
- [x] Dark mode support via semantic `Theme` colors
- [x] App icon set and all required sizes present
- [x] `LSMinimumSystemVersion` set correctly in Info.plist
- [x] `CODE_SIGN_IDENTITY` set to `-` for ad-hoc builds

### Account & App Store Connect
- [ ] Apple Developer account active (Individual or Organization)
- [ ] App Store Connect record created with correct Bundle ID
- [ ] Primary language set
- [ ] Age rating questionnaire completed
- [ ] Privacy policy URL hosted and accessible
- [ ] Support URL hosted and accessible

### Metadata
- [ ] App name: **StillMac**
- [ ] Tagline: **"Breathe. Be present."**
- [ ] Subtitle: A mindful meditation companion for your Mac
- [ ] Description written and reviewed
- [ ] Keywords configured (meditation, mindfulness, calm, breathing, focus, sleep, anxiety, mac)
- [ ] Category: Health & Fitness > Meditation
- [ ] Contact email configured

### Screenshots
- [ ] 3 screenshots at 2560×1600 px (1280×800 pt @2x)
- [ ] Light, calm aesthetic — no dark or busy backgrounds
- [ ] Screenshot 1: Main player / breathing orb
- [ ] Screenshot 2: Session library or journey view
- [ ] Screenshot 3: Stats or community view

### App Icon
- [ ] 1024×1024 px master icon uploaded
- [ ] All required sizes auto-generated
- [ ] Icon visually represents calm/breathing theme

## Submission

### Build Configuration
- [ ] XcodeGen `project.yml` generates correctly
- [ ] Xcode Cloud or local CI builds the `.app`
- [ ] Build is code-signed (even if ad-hoc for TestFlight)
- [ ] Upload to App Store Connect via Xcode Organizer or `xcrun altool`

### Review
- [ ] In-app purchases/subscriptions reviewed (if any)
- [ ] No placeholder or test content visible
- [ ] All UI strings are final (no "Lorem ipsum")
- [ ] External URLs are real and functional

## Post-Approval

- [ ] TestFlight beta invited to early users
- [ ] Release notes written for App Store update
- [ ] Launch day monitoring (build status, reviews)
- [ ] Social/community announcement prepared
- [ ] Analytics configured (optional, e.g. Apple Analytics)
