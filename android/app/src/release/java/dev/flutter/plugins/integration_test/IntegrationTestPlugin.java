package dev.flutter.plugins.integration_test;

import io.flutter.embedding.engine.plugins.FlutterPlugin;

/**
 * The Flutter 3.35.7 generated registrant includes dev-dependency plugins in
 * main Java source, while the release Gradle plugin loader correctly excludes
 * their projects. Keep the release registrant compilable without bundling the
 * integration-test runner or its Android test dependencies.
 */
public final class IntegrationTestPlugin implements FlutterPlugin {
  @Override
  public void onAttachedToEngine(FlutterPluginBinding binding) {}

  @Override
  public void onDetachedFromEngine(FlutterPluginBinding binding) {}
}
