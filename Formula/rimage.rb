class Rimage < Formula
  desc "A tool for resizing images in bulk"
  homepage "https://github.com/SalOne22/rimage"
  version "0.9.1"
  license "MIT"

  if Hardware::CPU.intel?
    url "https://github.com/SalOne22/rimage/releases/download/v0.9.1/rimage-0.9.1-x86_64-apple-darwin.tar.gz"
    sha256 "a3489a73a593e215c44805d41534c7d57f5e9b5ea3392424c14420c8b9a3c95b"
  elsif Hardware::CPU.arm?
    url "https://github.com/SalOne22/rimage/releases/download/v0.9.1/rimage-0.9.1-aarch64-apple-darwin.tar.gz"
    sha256 "ded6895336b279c00595785ad281e41ff79466fc11ed4821fefc0a98505873cd"
  end

  def install
    bin.install "rimage"
  end

  test do
    system "#{bin}/rimage", "--version"
  end
end

