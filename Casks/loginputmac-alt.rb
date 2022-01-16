cask "loginputmac-alt" do
  version "2.5.3,24161"
  sha256 "a6111d21be1f28e7a8ea748c7b98d5168432c20d47ad6abe93b05867429f58f5"

  url "https://loginput-mac2.totest.top/loginputmac#{version.major}_latest.pkg",
      verified: "loginput-mac2.totest.top/"
  name "LoginputMac"
  desc "Chinese input method"
  homepage "https://im.logcg.com/loginputmac#{version.major}"

  livecheck do
    url "https://im.logcg.com/appcast#{version.major}.xml"
    strategy :sparkle
  end

  auto_updates true

  pkg "loginputmac#{version.major}_latest.pkg"

  uninstall pkgutil: "com.logcg.pkg.LoginputMac#{version.major}",
            quit:    "com.logcg.inputmethod.LogInputMac#{version.major}"
  
  zap trash: [
    "~/Library/Application Support/LogInputMac",
    "~/Library/Application Support/com.logcg.inputmethod.LogInputMac2",
    "~/Library/Cookies/com.logcg.inputmethod.LogInputMac2.binarycookies",
    "~/Library/Preferences/com.logcg.inputmethod.LogInputMac.Settings.plist",
    "~/Library/Preferences/com.logcg.inputmethod.LogInputMac2.plist",
    "~/Library/Saved Application State/com.logcg.inputmethod.LogInputMac.Settings.savedState",
  ]
end
