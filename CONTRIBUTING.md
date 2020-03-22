# Contributing

### Issues
When opening an issue, try to be specific. For example, if you are opening an issue relating to the build process in android, it is helpful to include a stack trace and the gradle version you are using.

I usually will reply to an issue within the first 24hrs or so asking for more information or providing help. If the issue requires a code fix, this will take longer.

### Pull Requests
I'm always looking for additional help and am welcome to PRs! One thing to note, I am a big fan of understanding why code is being added or removed. So if you open a PR, please reference a link to why that change is being done (ex: Apple's docs say to do this... + link). This helps get the code merged in faster (otherwise, I will search the web and docs for the reason you are providing the PR.) and I think it helps other open programmers too.

### Design of Code
This package is built for react developers. This means that the native code should not restrict the javascript functionality and instead supply a robust API. For example, instead of implementing a "Focus on Point" feature in iOS and Android, we instead supply the javascript with an api to focus the camera. The javascript developer can then implement their own algorithm for camera focusing if they wish. **When requesting a feature or creating a PR, you should take this into account**
