cask "ogdesign-eagle" do
    arch intel: "x64"
  
    version "4.0,1"
    sha256 intel: "56843367bc3e1e79046520cc4f9a17b9904b533efc111e9d27d3c1c94976ba0b"
  
    url "https://eaglefile.oss-cn-shenzhen.aliyuncs.com/releases/Eagle-#{version.csv.first}-#{arch}-build#{version.csv.second}.dmg",
        verified: "eaglefile.oss-cn-shenzhen.aliyuncs.com/releases/"
    name "Eagle"
    desc "Organise all your reference images in one place"
    homepage "https://eagle.cool/"
  
    livecheck do
      url "https://eagle.cool/check-for-update"
      regex(/Eagle[._-]v?(\d+(?:\.\d+)+)-#{arch}[._-]?build(\d+(?:\.\d+)*)\.dmg/i)
      strategy :page_match do |page, regex|
        match = page.match(regex)
        next if match.blank?
  
        "#{match[1]},#{match[2]}"
      end
    end
  
    auto_updates true
    depends_on macos: ">= :high_sierra"
  
    app "Eagle.app"
  
    zap trash: [
      "~/Library/Application Support/Eagle",
      "~/Library/Logs/Eagle",
      "~/Library/Preferences/tw.ogdesign.eagle.plist",
      "~/Library/Saved Application State/tw.ogdesign.eagle.savedState",
    ]
  end