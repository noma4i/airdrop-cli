{
  "targets": [
    {
      "target_name": "airdrop_native",
      "sources": [
        "src/native/airdrop_native.mm"
      ],
      "defines": [
        "NAPI_VERSION=3"
      ],
      "cflags!": ["-fno-exceptions"],
      "cflags_cc!": ["-fno-exceptions"],
      "xcode_settings": {
        "GCC_ENABLE_CPP_EXCEPTIONS": "YES",
        "CLANG_CXX_LIBRARY": "libc++",
        "MACOSX_DEPLOYMENT_TARGET": "10.12",
        "OTHER_CPLUSPLUSFLAGS": [
          "-std=c++17",
          "-stdlib=libc++"
        ]
      },
      "link_settings": {
        "libraries": [
          "-framework Cocoa",
          "-framework Foundation"
        ]
      }
    }
  ]
}
