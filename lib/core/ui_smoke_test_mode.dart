/// Test-only safeguards for authenticated staging UI smoke tests.
///
/// Enable only in an integration-test invocation with
/// `--dart-define=EVERYWEAR_UI_SMOKE_TEST=true`. Never set this in beta builds.
const bool everywearUiSmokeTestMode = bool.fromEnvironment(
  'EVERYWEAR_UI_SMOKE_TEST',
  defaultValue: false,
);
