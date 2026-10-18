# Native validation

Element Studio is tested as a SwiftUI/RealityKit iOS app. From the repository root:

```sh
python3 scripts/check_repository.py
python3 scripts/test-native.py
```

The native helper builds and runs unit and UI tests in a dedicated iPhone simulator, or on a connected iPhone with `--device DEVICE_UDID --team YOUR_TEAM_ID`. It saves logs and `.xcresult` bundles under `build/`. No browser or Node installation is needed for app testing.

The portable [native validation guide](../skills/element-studio/references/native-validation.md) contains simulator discovery, device signing and installation, isolated review storage, capture commands, and the visual acceptance matrix. It is included inside the Element Studio skill so other agents can use the same workflow after installing that skill.

GitHub Actions is configured to run repository checks and the native suites on the `xcode-27` macOS runner. That runner label is currently a GitHub public preview; see [GitHub's hosted runner reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners). Hosted execution also depends on the account's Actions availability; see [the release record](OPEN-SOURCE.md).
