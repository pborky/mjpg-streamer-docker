variable "PKG_PROXY"  {  }
variable "GIT_BRANCH" {  }
variable "BUILD_DATE" {  }
variable "TAG"  { default = "master" }

group "default" {
  targets = [ 
    "mjpeg-streamer", "latest", "date"
    ]
}

target "latest" {
  inherits = ["mjpeg-streamer"]
  tags = [ 
    "mindspy/mjpeg-streamer:latest",
    "mindspy/mjpeg-streamer:latest-stage",
    "mindspy/mjpeg-streamer:latest-export"
  ]
}

target "date" {
  inherits = ["mjpeg-streamer"]
  tags = [ "mindspy/mjpeg-streamer:${BUILD_DATE}" ]
}

target "dev" {
  tags = [ "mindspy/pigen:dev" ]
  inherits = ["mjpeg-streamer"]
}
target "mjpeg-streamer" {
  platforms = [ 
    "linux/arm64/v8", "linux/arm/v7"
    ]
  context = "."
  tags = [ "mindspy/mjpeg-streamer:${TAG}" ]
  args = {
      RELEASE = "3.15"
      PKG_PROXY = "${PKG_PROXY}"
      TAG = "${TAG}"
    }
}
