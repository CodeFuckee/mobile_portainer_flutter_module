# Bug 修复需求：gitlab runner运行selenium测试出现新的报错 There is an unknown failure

## gitlab ci日志
2026-07-22T15:36:52.275072Z 00O [0KRunning with gitlab-runner 19.1.1 (24b9b726)[0;m
2026-07-22T15:36:52.275095Z 00O [0K  on ckd-Code-01-Series-PF5NU1G VbJUETEvA, system ID: s_f7848d3f5058[0;m
2026-07-22T15:36:52.275139Z 00O section_start:1784734612:prepare_executor
[0K
2026-07-22T15:36:52.275145Z 00O+[0K[36;1mPreparing the "shell" executor[0;m[0;m
2026-07-22T15:36:52.275289Z 00O [0KUsing Shell (bash) executor...[0;m
2026-07-22T15:36:52.275292Z 00O section_end:1784734612:prepare_executor
[0K
2026-07-22T15:36:52.275483Z 00O+section_start:1784734612:prepare_script
[0K
2026-07-22T15:36:52.275488Z 00O+[0K[36;1mPreparing environment[0;m[0;m
2026-07-22T15:36:52.291640Z 01O Running on ckd-Code-01-Series-PF5NU1G...
2026-07-22T15:36:52.298055Z 00O section_end:1784734612:prepare_script
[0K
2026-07-22T15:36:52.298421Z 00O+section_start:1784734612:get_sources
[0K
2026-07-22T15:36:52.298425Z 00O+[0K[36;1mGetting source from Git repository[0;m[0;m
2026-07-22T15:36:52.360290Z 01O [32;1mGitaly correlation ID: 01KY57HY0NWXT119GFYH5X1KSY[0;m
2026-07-22T15:36:52.379660Z 01O [32;1mFetching changes with git depth set to 20...[0;m
2026-07-22T15:36:52.382259Z 01O Reinitialized existing Git repository in /home/ckd/builds/VbJUETEvA/0/chenkaidi/mobile_portainer_flutter_module/.git/
2026-07-22T15:36:52.685833Z 01O [32;1mChecking out 2fa5df9d as detached HEAD (ref is main)...[0;m
2026-07-22T15:36:52.693495Z 01O [32;1mSkipping Git submodules setup[0;m
2026-07-22T15:36:52.694859Z 00O section_end:1784734612:get_sources
[0K
2026-07-22T15:36:52.695623Z 00O+section_start:1784734612:download_artifacts
[0K
2026-07-22T15:36:52.695630Z 00O+[0K[36;1mDownloading artifacts[0;m[0;m
2026-07-22T15:36:52.803974Z 01O [32;1mDownloading artifacts for flutter_build_web (1159)...[0;m
2026-07-22T15:36:52.868803Z 01E Runtime platform                                  [0;m  arch[0;m=amd64 os[0;m=linux pid[0;m=331667 revision[0;m=24b9b726 version[0;m=19.1.1
2026-07-22T15:36:54.047026Z 01E Downloading artifacts from coordinator... ok      [0;m  correlation_id[0;m=01KY57HZE524Q29BSMAKGNQQ0E id[0;m=1159 status[0;m=200 token[0;m=65_4pTNcL
2026-07-22T15:36:54.300134Z 01E [0;33mWARNING: build/web/: lchown build/web/: operation not permitted (suppressing repeats)[0;m 
2026-07-22T15:36:54.313886Z 00O section_end:1784734614:download_artifacts
[0K
2026-07-22T15:36:54.314156Z 00O+section_start:1784734614:step_script
[0K
2026-07-22T15:36:54.314162Z 00O+[0K[36;1mExecuting "step_script" stage of the job script[0;m[0;m
2026-07-22T15:36:54.351998Z 01O [32;1m$ echo "step0 start"[0;m
2026-07-22T15:36:54.352018Z 01O step0 start
2026-07-22T15:36:54.352019Z 01O [32;1m$ docker --version[0;m
2026-07-22T15:36:54.375279Z 01O Docker version 29.6.2, build dfc4efb
2026-07-22T15:36:54.375581Z 01O [32;1m$ echo "step1 verify web build"[0;m
2026-07-22T15:36:54.375583Z 01O step1 verify web build
2026-07-22T15:36:54.375589Z 01O [32;1m$ ls -la build/web/index.html[0;m
2026-07-22T15:36:54.377991Z 01O -rw-rw-rw- 1 ckd ckd 1552 Jul 22 23:36 build/web/index.html
2026-07-22T15:36:54.378340Z 01O [32;1m$ echo "step2 pull python image"[0;m
2026-07-22T15:36:54.378342Z 01O step2 pull python image
2026-07-22T15:36:54.378343Z 01O [32;1m$ docker pull docker.1ms.run/python:3.11-slim 2>&1[0;m
2026-07-22T15:36:54.965522Z 01O 3.11-slim: Pulling from python

## 修复验证
修复之后，将代码推送到gitlab上，并通过glab工具确认ci cd流水线成功运行selenium_tests阶段