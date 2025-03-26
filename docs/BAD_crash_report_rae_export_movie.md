-------------------------------------
Translated Report (Full Report Below)
-------------------------------------

Process:               edit [97235]
Path:                  /Users/USER/Documents/*/edit
Identifier:            edit
Version:               ???
Code Type:             ARM-64 (Native)
Parent Process:        Exited process [97125]
Responsible:           wezterm-gui [46218]
User ID:               501

Date/Time:             2025-03-25 22:11:15.4541 -0400
OS Version:            macOS 14.2.1 (23C71)
Report Version:        12
Anonymous UUID:        F03D0247-0FBD-2B4F-EE03-1472490A30EE

Sleep/Wake UUID:       6969127B-6EB4-4A1E-AF3C-8F2C00500E34

Time Awake Since Boot: 620000 seconds
Time Since Wake:       19146 seconds

System Integrity Protection: enabled

Crashed Thread:        11

Exception Type:        EXC_BAD_ACCESS (SIGSEGV)
Exception Codes:       KERN_INVALID_ADDRESS at 0x0000000000000030
Exception Codes:       0x0000000000000001, 0x0000000000000030

Termination Reason:    Namespace SIGNAL, Code 11 Segmentation fault: 11
Terminating Process:   exc handler [97235]

VM Region Info: 0x30 is not in any region.  Bytes before following region: 4303355856
      REGION TYPE                    START - END         [ VSIZE] PRT/MAX SHRMOD  REGION DETAIL
      UNUSED SPACE AT START
--->  
      __TEXT                      100800000-10083c000    [  240K] r-x/r-x SM=COW  ...uments/*/edit

Thread 0::  Dispatch queue: com.apple.main-thread
0   libraylib.5.5.0.dylib         	       0x100ea2998 DrawTextEx + 144
1   libraylib.5.5.0.dylib         	       0x100ea2864 DrawText + 112
2   libraylib.5.5.0.dylib         	       0x100ea2864 DrawText + 112
3   edit                          	       0x10081e890 tpp_method_Drawer_Text + 84
4   edit                          	       0x10080dc10 ElementTimelineUI + 1868
5   edit                          	       0x10080c2c8 GameTick + 2060
6   edit                          	       0x10080b5ec main + 4188
7   dyld                          	       0x18d1690e0 start + 2360

Thread 1:
0   libsystem_pthread.dylib       	       0x18d4e4e28 start_wqthread + 0

Thread 2:
0   libsystem_pthread.dylib       	       0x18d4e4e28 start_wqthread + 0

Thread 3:: com.apple.NSEventThread
0   libsystem_kernel.dylib        	       0x18d4a9874 mach_msg2_trap + 8
1   libsystem_kernel.dylib        	       0x18d4bbcf0 mach_msg2_internal + 80
2   libsystem_kernel.dylib        	       0x18d4b24b0 mach_msg_overwrite + 476
3   libsystem_kernel.dylib        	       0x18d4a9bf8 mach_msg + 24
4   CoreFoundation                	       0x18d5c7bf4 __CFRunLoopServiceMachPort + 160
5   CoreFoundation                	       0x18d5c64bc __CFRunLoopRun + 1208
6   CoreFoundation                	       0x18d5c59ac CFRunLoopRunSpecific + 608
7   AppKit                        	       0x190ecc510 _NSEventThread + 144
8   libsystem_pthread.dylib       	       0x18d4ea034 _pthread_start + 136
9   libsystem_pthread.dylib       	       0x18d4e4e3c thread_start + 8

Thread 4:
0   libsystem_pthread.dylib       	       0x18d4e4e28 start_wqthread + 0

Thread 5:: caulk.messenger.shared:17
0   libsystem_kernel.dylib        	       0x18d4a97f0 semaphore_wait_trap + 8
1   caulk                         	       0x197870690 caulk::semaphore::timed_wait(double) + 212
2   caulk                         	       0x197870544 caulk::concurrent::details::worker_thread::run() + 36
3   caulk                         	       0x197870244 void* caulk::thread_proxy<std::__1::tuple<caulk::thread::attributes, void (caulk::concurrent::details::worker_thread::*)(), std::__1::tuple<caulk::concurrent::details::worker_thread*>>>(void*) + 96
4   libsystem_pthread.dylib       	       0x18d4ea034 _pthread_start + 136
5   libsystem_pthread.dylib       	       0x18d4e4e3c thread_start + 8

Thread 6:: caulk.messenger.shared:high
0   libsystem_kernel.dylib        	       0x18d4a97f0 semaphore_wait_trap + 8
1   caulk                         	       0x197870690 caulk::semaphore::timed_wait(double) + 212
2   caulk                         	       0x197870544 caulk::concurrent::details::worker_thread::run() + 36
3   caulk                         	       0x197870244 void* caulk::thread_proxy<std::__1::tuple<caulk::thread::attributes, void (caulk::concurrent::details::worker_thread::*)(), std::__1::tuple<caulk::concurrent::details::worker_thread*>>>(void*) + 96
4   libsystem_pthread.dylib       	       0x18d4ea034 _pthread_start + 136
5   libsystem_pthread.dylib       	       0x18d4e4e3c thread_start + 8

Thread 7:: caulk::deferred_logger
0   libsystem_kernel.dylib        	       0x18d4a97f0 semaphore_wait_trap + 8
1   caulk                         	       0x197870690 caulk::semaphore::timed_wait(double) + 212
2   caulk                         	       0x197870544 caulk::concurrent::details::worker_thread::run() + 36
3   caulk                         	       0x197870244 void* caulk::thread_proxy<std::__1::tuple<caulk::thread::attributes, void (caulk::concurrent::details::worker_thread::*)(), std::__1::tuple<caulk::concurrent::details::worker_thread*>>>(void*) + 96
4   libsystem_pthread.dylib       	       0x18d4ea034 _pthread_start + 136
5   libsystem_pthread.dylib       	       0x18d4e4e3c thread_start + 8

Thread 8:: com.apple.audio.IOThread.client
0   libsystem_kernel.dylib        	       0x18d4a9874 mach_msg2_trap + 8
1   libsystem_kernel.dylib        	       0x18d4bbcf0 mach_msg2_internal + 80
2   libsystem_kernel.dylib        	       0x18d4b24b0 mach_msg_overwrite + 476
3   libsystem_kernel.dylib        	       0x18d4a9bf8 mach_msg + 24
4   CoreAudio                     	       0x18fe33ca0 HALB_MachPort::SendSimpleMessageWithSimpleReply(unsigned int, unsigned int, int, int&, bool, unsigned int) + 96
5   CoreAudio                     	       0x18fd0ab84 HALC_ProxyIOContext::IOWorkLoop() + 4260
6   CoreAudio                     	       0x18fd093b0 invocation function for block in HALC_ProxyIOContext::HALC_ProxyIOContext(unsigned int, unsigned int) + 108
7   CoreAudio                     	       0x18fe88564 HALC_IOThread::Entry(void*) + 88
8   libsystem_pthread.dylib       	       0x18d4ea034 _pthread_start + 136
9   libsystem_pthread.dylib       	       0x18d4e4e3c thread_start + 8

Thread 9:
0   libsystem_pthread.dylib       	       0x18d4e4e28 start_wqthread + 0

Thread 10:
0   libsystem_pthread.dylib       	       0x18d4e4e28 start_wqthread + 0

Thread 11 Crashed:
0   libGL.dylib                   	       0x1f5db98f8 glBindTexture + 16
1   libraylib.5.5.0.dylib         	       0x100e5f0bc rlReadTexturePixels + 60
2   libraylib.5.5.0.dylib         	       0x100eaf4dc LoadImageFromTexture + 56
3   edit                          	       0x10080e9bc ExportVideo + 88
4   edit                          	       0x10080e948 ExportVideoThread + 40
5   libsystem_pthread.dylib       	       0x18d4ea034 _pthread_start + 136
6   libsystem_pthread.dylib       	       0x18d4e4e3c thread_start + 8


Thread 11 crashed with ARM Thread State (64-bit):
    x0: 0x0000000000000de1   x1: 0x0000000000000de1   x2: 0x0000000000000003   x3: 0x0000000000000007
    x4: 0x000000016fbff000   x5: 0x00000000190008ff   x6: 0x0000000000000000   x7: 0x0000000000000000
    x8: 0x0000000000000000   x9: 0x000000016fbfee68  x10: 0x2b0b87bdcd2500ec  x11: 0x0000000000000000
   x12: 0x0000000000000000  x13: 0x0000000000000000  x14: 0x0000000000000000  x15: 0x0000000000000000
   x16: 0x0000000100eaf4a4  x17: 0x00000001ecd3b3d0  x18: 0x0000000000000000  x19: 0x0000000000000007
   x20: 0x0000000000000003  x21: 0x0000000000000384  x22: 0x00000000000004b0  x23: 0x0000000100f1d000
   x24: 0x0000000000000000  x25: 0x0000000000000000  x26: 0x0000000000000000  x27: 0x0000000000000000
   x28: 0x0000000000000000   fp: 0x000000016fbfed20   lr: 0x0000000100e5f0bc
    sp: 0x000000016fbfecd0   pc: 0x00000001f5db98f8 cpsr: 0x80001000
   far: 0x0000000000000030  esr: 0x92000006 (Data Abort) byte read Translation fault

Binary Images:
       0x116934000 -        0x116a6bfff com.apple.audio.units.Components (1.14) <06275638-4d71-370d-bf96-b30a567270e1> /System/Library/Components/CoreAudio.component/Contents/MacOS/CoreAudio
       0x105d54000 -        0x105dbffff com.apple.AppleMetalOpenGLRenderer (1.0) <41cb4d99-6a07-366a-9e97-d047ce10daa2> /System/Library/Extensions/AppleMetalOpenGLRenderer.bundle/Contents/MacOS/AppleMetalOpenGLRenderer
       0x103cb0000 -        0x103cbbfff libobjc-trampolines.dylib (*) <7778e0d7-361a-378d-9438-3b2bb48c2154> /usr/lib/libobjc-trampolines.dylib
       0x100898000 -        0x1008abfff libscript.dylib (*) <c864d4a5-e7a1-3527-976b-8ea179daadf4> /Users/USER/Documents/*/libscript.dylib
       0x100e08000 -        0x100f0bfff libraylib.5.5.0.dylib (*) <04958d5f-6d60-33ea-a976-f5919f8313f8> /opt/homebrew/*/libraylib.5.5.0.dylib
       0x101930000 -        0x10224ffff libavcodec.61.19.100.dylib (*) <6a122518-7dcc-316f-875e-ae7f2b09222f> /opt/homebrew/*/libavcodec.61.19.100.dylib
       0x1011ac000 -        0x101393fff libavformat.61.7.100.dylib (*) <59b4d0b8-63ca-3178-9dea-4a2355c2d142> /opt/homebrew/*/libavformat.61.7.100.dylib
       0x1028b4000 -        0x102927fff libavutil.59.39.100.dylib (*) <9e2c663b-35ee-3078-8f6b-c0059eeeae5f> /opt/homebrew/*/libavutil.59.39.100.dylib
       0x100d24000 -        0x100d83fff libswscale.8.3.100.dylib (*) <5bf08f2a-b2e3-337d-a774-867032d3604c> /opt/homebrew/*/libswscale.8.3.100.dylib
       0x100cd4000 -        0x100ce7fff libswresample.5.3.100.dylib (*) <19aa942c-c213-3eff-8213-efae88154340> /opt/homebrew/*/libswresample.5.3.100.dylib
       0x1013ec000 -        0x10155ffff libvpx.9.dylib (*) <0ad3c1cf-cb22-3842-aaa4-293bf557c97a> /opt/homebrew/*/libvpx.9.dylib
       0x100cf4000 -        0x100cfbfff libwebpmux.3.1.0.dylib (*) <a18155e2-fd5b-3735-9604-f964f0ab8683> /opt/homebrew/*/libwebpmux.3.1.0.dylib
       0x100dcc000 -        0x100debfff liblzma.5.dylib (*) <131a4891-8890-3954-97e3-78c25a374e98> /opt/homebrew/*/liblzma.5.dylib
       0x100d08000 -        0x100d17fff libaribb24.0.dylib (*) <ad2f19ff-f755-3588-93ca-3e3025243524> /opt/homebrew/*/libaribb24.0.dylib
       0x101030000 -        0x1010c7fff libdav1d.7.dylib (*) <0320d976-fc09-3758-95af-f72e7d760916> /opt/homebrew/*/libdav1d.7.dylib
       0x100d9c000 -        0x100dabfff libopencore-amrwb.0.dylib (*) <b385f9c0-2a73-3648-976d-a34f41304f46> /opt/homebrew/*/libopencore-amrwb.0.dylib
       0x100f6c000 -        0x100f73fff libsnappy.1.2.1.dylib (*) <2e01fa4f-06ab-327c-b0ce-4b0a0931e5b3> /opt/homebrew/*/libsnappy.1.2.1.dylib
       0x103d44000 -        0x1040a3fff libaom.3.11.0.dylib (*) <f662f185-80b8-3f8c-bf61-5315a885456d> /opt/homebrew/*/libaom.3.11.0.dylib
       0x101654000 -        0x10167bfff libvmaf.3.dylib (*) <7ef169d5-d3ae-3a2e-90fe-0b633c6ccf99> /opt/homebrew/*/libvmaf.3.dylib
       0x103960000 -        0x103aaffff libjxl.0.11.1.dylib (*) <f0839603-0586-37af-9de9-147772ced9f6> /opt/homebrew/*/libjxl.0.11.1.dylib
       0x100cc4000 -        0x100cc7fff libjxl_threads.0.11.1.dylib (*) <16d7ae78-47cc-3e05-aa73-f5ab4757d1b7> /opt/homebrew/*/libjxl_threads.0.11.1.dylib
       0x10112c000 -        0x101163fff libmp3lame.0.dylib (*) <68e5cf9a-d53f-3676-842f-ebc85f005698> /opt/homebrew/*/libmp3lame.0.dylib
       0x100fb0000 -        0x100fcffff libopencore-amrnb.0.dylib (*) <4f75e4c3-734d-3dc9-8a39-9fadb7a09d38> /opt/homebrew/*/libopencore-amrnb.0.dylib
       0x10159c000 -        0x1015dbfff libopenjp2.2.5.3.dylib (*) <909347a2-9b4d-3a68-bea0-1754ce12e3ce> /opt/homebrew/*/libopenjp2.2.5.3.dylib
       0x10174c000 -        0x101793fff libopus.0.dylib (*) <20f4d666-162c-30c8-88e0-c962e1faacdf> /opt/homebrew/*/libopus.0.dylib
       0x104420000 -        0x1045fffff librav1e.0.7.1.dylib (*) <36de9c5f-9d32-3e23-a529-a9cd2f35182a> /opt/homebrew/*/librav1e.0.7.1.dylib
       0x100fe0000 -        0x100ff3fff libspeex.1.dylib (*) <546d9e85-d9f2-3a01-a64a-77307884d24a> /opt/homebrew/*/libspeex.1.dylib
       0x104984000 -        0x104be3fff libSvtAv1Enc.2.2.0.dylib (*) <58566809-7a99-3e27-97f0-537120e21930> /opt/homebrew/*/libSvtAv1Enc.2.2.0.dylib
       0x1017a4000 -        0x1017c7fff libtheoraenc.1.dylib (*) <22c1a2e4-e4e0-3f0b-a401-f27730148761> /opt/homebrew/*/libtheoraenc.1.dylib
       0x101004000 -        0x10100ffff libtheoradec.1.dylib (*) <a03d1876-ebc8-3326-b48a-7e46189cb986> /opt/homebrew/*/libtheoradec.1.dylib
       0x100f98000 -        0x100f9ffff libogg.0.dylib (*) <7343af8b-ee18-3518-ac9e-86729a8083ef> /opt/homebrew/*/libogg.0.dylib
       0x1017d8000 -        0x1017fbfff libvorbis.0.dylib (*) <edb49fa1-7896-3e7f-8b16-813fc1b05112> /opt/homebrew/*/libvorbis.0.dylib
       0x103b44000 -        0x103bbbfff libvorbisenc.2.dylib (*) <2664b493-7704-3fd9-a41f-9fe10b9dfb62> /opt/homebrew/*/libvorbisenc.2.dylib
       0x10180c000 -        0x10184bfff libwebp.7.1.9.dylib (*) <b244e1ca-e3fe-3897-a0a3-d14ed220a88b> /opt/homebrew/*/libwebp.7.1.9.dylib
       0x104174000 -        0x104297fff libx264.164.dylib (*) <cdbfaf38-a184-31fe-abd6-7ff7ddf2f0ef> /opt/homebrew/*/libx264.164.dylib
       0x10520c000 -        0x105567fff libx265.212.dylib (*) <00683954-7bb2-39f5-ab69-c1ef0d374e5d> /opt/homebrew/*/libx265.212.dylib
       0x101864000 -        0x101883fff libsoxr.0.1.2.dylib (*) <f0c93f6f-447e-3469-a155-47bf9611e4b7> /opt/homebrew/*/libsoxr.0.1.2.dylib
       0x1046cc000 -        0x10479ffff libX11.6.dylib (*) <2a4ca82f-7c9e-3814-9840-4fe71cb271d2> /opt/homebrew/*/libX11.6.dylib
       0x101620000 -        0x101633fff libxcb.1.1.0.dylib (*) <8ef9b9ff-3f1e-39a6-bec1-e7d10db8e6cb> /opt/homebrew/*/libxcb.1.1.0.dylib
       0x1015f0000 -        0x1015f3fff libXau.6.0.0.dylib (*) <52eda2b7-12f8-3daa-888b-d615e658c4f0> /opt/homebrew/*/libXau.6.0.0.dylib
       0x100dbc000 -        0x100dbffff libXdmcp.6.dylib (*) <11368a67-e3a3-3d6f-ae03-78456881a92e> /opt/homebrew/*/libXdmcp.6.dylib
       0x101604000 -        0x101607fff libsharpyuv.0.1.0.dylib (*) <62623b16-60a4-32f6-81a4-585016484956> /opt/homebrew/*/libsharpyuv.0.1.0.dylib
       0x1018fc000 -        0x10191ffff libpng16.16.dylib (*) <f00fd0e9-dac7-3ef5-bd8f-a4b5f3a57dd1> /opt/homebrew/*/libpng16.16.dylib
       0x103bf8000 -        0x103c03fff libjxl_cms.0.11.1.dylib (*) <94cae2b8-9af4-3162-8135-39c184af4cbb> /opt/homebrew/*/libjxl_cms.0.11.1.dylib
       0x1018c8000 -        0x1018cffff libhwy.1.2.0.dylib (*) <35666841-18ae-32b3-a37b-d33d3c347610> /opt/homebrew/*/libhwy.1.2.0.dylib
       0x1018e0000 -        0x1018ebfff libbrotlidec.1.1.0.dylib (*) <2b673811-9400-3f1c-8ec0-d2a7d4b75e2c> /opt/homebrew/*/libbrotlidec.1.1.0.dylib
       0x103c40000 -        0x103c5ffff libbrotlicommon.1.1.0.dylib (*) <d6d17b55-1cd9-3744-8d06-c9990225fa39> /opt/homebrew/*/libbrotlicommon.1.1.0.dylib
       0x1047c8000 -        0x104853fff libbrotlienc.1.1.0.dylib (*) <9c06eacb-6f5c-3267-a89a-39103dc342fc> /opt/homebrew/*/libbrotlienc.1.1.0.dylib
       0x103cc4000 -        0x103cfffff liblcms2.2.dylib (*) <e7a6ea33-e47c-3548-90d4-1eed45091886> /opt/homebrew/*/liblcms2.2.dylib
       0x1043ac000 -        0x1043ebfff libbluray.2.dylib (*) <26c4f6f7-5d39-3c12-831a-a852dc21c318> /opt/homebrew/*/libbluray.2.dylib
       0x104f50000 -        0x1050c3fff libgnutls.30.dylib (*) <59e2dd5f-5401-3d77-8546-4e94b8552035> /opt/homebrew/*/libgnutls.30.dylib
       0x104868000 -        0x104883fff librist.4.dylib (*) <36312e14-9b42-3cbb-a86a-c7c01c736022> /opt/homebrew/*/librist.4.dylib
       0x104d84000 -        0x104df3fff libsrt.1.5.4.dylib (*) <f9e45ab1-72ef-3d68-b946-46b5dd512dd7> /opt/homebrew/*/libsrt.1.5.4.dylib
       0x104e34000 -        0x104e87fff libssh.4.10.1.dylib (*) <56d71248-3350-3760-99eb-3f50efe86eb8> /opt/homebrew/*/libssh.4.10.1.dylib
       0x104eac000 -        0x104f03fff libzmq.5.dylib (*) <8f363bb6-d8b9-3179-b0b7-e1914a93eea9> /opt/homebrew/*/libzmq.5.dylib
       0x104898000 -        0x1048cbfff libfontconfig.1.dylib (*) <99ce4547-5924-35e1-aa62-6f1d4a8289cd> /opt/homebrew/*/libfontconfig.1.dylib
       0x105120000 -        0x10519bfff libfreetype.6.dylib (*) <26d566c1-3b1f-30fb-ba97-0413177dae5e> /opt/homebrew/*/libfreetype.6.dylib
       0x103c6c000 -        0x103c83fff libintl.8.dylib (*) <9924fd2d-8556-34b2-add9-ab2838b3359b> /opt/homebrew/*/libintl.8.dylib
       0x10580c000 -        0x105903fff libp11-kit.0.dylib (*) <5ab305be-ee60-302b-a5e4-2b42f5ea5103> /opt/homebrew/*/libp11-kit.0.dylib
       0x104924000 -        0x104953fff libidn2.0.dylib (*) <a980ce71-e631-397d-a451-452a3a0be6ec> /opt/homebrew/*/libidn2.0.dylib
       0x105b64000 -        0x105d2ffff libunistring.5.dylib (*) <e8557d4d-ca9a-3119-bee5-b246473a46c0> /opt/homebrew/*/libunistring.5.dylib
       0x103c94000 -        0x103c9ffff libtasn1.6.dylib (*) <799845d9-7beb-30fa-89ea-542d4e6d2590> /opt/homebrew/*/libtasn1.6.dylib
       0x1056f8000 -        0x10572ffff libnettle.8.9.dylib (*) <35ded263-acb6-333d-91c3-c2e07cfecca3> /opt/homebrew/*/libnettle.8.9.dylib
       0x10574c000 -        0x105787fff libhogweed.6.9.dylib (*) <c360b13b-689f-3ac7-b03d-b6f5d40ec43c> /opt/homebrew/*/libhogweed.6.9.dylib
       0x105974000 -        0x1059cbfff libgmp.10.dylib (*) <f6a7b957-4314-3ea5-ac52-39a649bd3a58> /opt/homebrew/*/libgmp.10.dylib
       0x105a64000 -        0x105ab7fff libmbedcrypto.3.6.2.dylib (*) <fa46eba9-6fb7-3b1f-95b1-6070d4230fa8> /opt/homebrew/*/libmbedcrypto.3.6.2.dylib
       0x103c14000 -        0x103c17fff libcjson.1.7.18.dylib (*) <f02fe1c5-1dce-387a-a4e2-d6f37957fe4c> /opt/homebrew/*/libcjson.1.7.18.dylib
       0x105e28000 -        0x105eb3fff libssl.3.dylib (*) <97f508a8-5334-38d1-add5-2d786550cdb3> /opt/homebrew/*/libssl.3.dylib
       0x10631c000 -        0x10660ffff libcrypto.3.dylib (*) <ec558165-eb5e-35a2-8fe0-aa335b3fed24> /opt/homebrew/*/libcrypto.3.dylib
       0x1056a4000 -        0x1056cffff libsodium.26.dylib (*) <56c8d86f-7358-3639-8b41-7605cb5e8c7c> /opt/homebrew/*/libsodium.26.dylib
       0x100800000 -        0x10083bfff edit (*) <d312573b-b559-353d-9509-076f0ceb5bc8> /Users/USER/Documents/*/edit
       0x18d163000 -        0x18d1f7347 dyld (*) <324e4ad9-e01f-3183-b09f-3e20b326643a> /usr/lib/dyld
               0x0 - 0xffffffffffffffff ??? (*) <00000000-0000-0000-0000-000000000000> ???
       0x18d4e3000 -        0x18d4efff3 libsystem_pthread.dylib (*) <a7d94c96-7b1f-3229-9bea-048d037c3292> /usr/lib/system/libsystem_pthread.dylib
       0x18d4a8000 -        0x18d4e2fff libsystem_kernel.dylib (*) <ca94fc21-bc40-3b43-b65d-b87ece9e1d48> /usr/lib/system/libsystem_kernel.dylib
       0x18d54a000 -        0x18da21fff com.apple.CoreFoundation (6.9) <47e4ec09-8f6e-30a8-99d0-34024d4f8122> /System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation
       0x190d69000 -        0x192083fff com.apple.AppKit (6.9) <f3527312-e426-3f7c-b77b-2bf49d1b7c04> /System/Library/Frameworks/AppKit.framework/Versions/C/AppKit
       0x19786e000 -        0x197897fff com.apple.audio.caulk (1.0) <25e50b84-b506-3db7-9a91-3824b9b8b880> /System/Library/PrivateFrameworks/caulk.framework/Versions/A/caulk
       0x18fb20000 -        0x190212fff com.apple.audio.CoreAudio (5.0) <2c54c60c-a5af-39f4-8286-0cb88fa43367> /System/Library/Frameworks/CoreAudio.framework/Versions/A/CoreAudio
       0x1f5db9000 -        0x1f5dc2fff libGL.dylib (*) <92b8b37d-0c5d-3f98-aede-56df6d84ae1f> /System/Library/Frameworks/OpenGL.framework/Versions/A/Libraries/libGL.dylib

External Modification Summary:
  Calls made by other processes targeting this process:
    task_for_pid: 0
    thread_create: 0
    thread_set_state: 0
  Calls made by this process:
    task_for_pid: 0
    thread_create: 0
    thread_set_state: 0
  Calls made by all processes on this machine:
    task_for_pid: 0
    thread_create: 0
    thread_set_state: 0

VM Region Summary:
ReadOnly portion of Libraries: Total=1.3G resident=0K(0%) swapped_out_or_unallocated=1.3G(100%)
Writable regions: Total=2.6G written=0K(0%) resident=0K(0%) swapped_out=0K(0%) unallocated=2.6G(100%)

                                VIRTUAL   REGION 
REGION TYPE                        SIZE    COUNT (non-coalesced) 
===========                     =======  ======= 
Accelerate framework               128K        1 
Activity Tracing                   256K        1 
CG image                            96K        5 
ColorSync                          592K       29 
CoreAnimation                      496K       31 
CoreGraphics                        48K        3 
CoreUI image data                  528K        7 
Foundation                          16K        1 
Kernel Alloc Once                   32K        1 
MALLOC                             2.5G       65 
MALLOC guard page                  192K       12 
OpenGL GLSL                        256K        3 
STACK GUARD                       56.2M       12 
Stack                             13.8M       12 
VM_ALLOCATE                       1872K       28 
VM_ALLOCATE (reserved)              32K        1         reserved VM address space (unallocated)
__AUTH                            1017K      226 
__AUTH_CONST                      17.5M      403 
__CTF                               824        1 
__DATA                            30.8M      460 
__DATA_CONST                      22.0M      477 
__DATA_DIRTY                      1036K      127 
__FONT_DATA                          4K        1 
__GLSLBUILTINS                    5174K        1 
__LINKEDIT                       900.5M       72 
__OBJC_RO                         71.1M        1 
__OBJC_RW                         2168K        1 
__TEXT                           409.0M      491 
dyld private memory                272K        2 
mapped file                      181.9M       25 
shared memory                      944K       15 
===========                     =======  ======= 
TOTAL                              4.2G     2515 
TOTAL, minus reserved VM space     4.2G     2515 



-----------
Full Report
-----------

{"app_name":"edit","timestamp":"2025-03-25 22:11:15.00 -0400","app_version":"","slice_uuid":"d312573b-b559-353d-9509-076f0ceb5bc8","build_version":"","platform":1,"share_with_app_devs":0,"is_first_party":1,"bug_type":"309","os_version":"macOS 14.2.1 (23C71)","roots_installed":0,"incident_id":"112492B3-2740-434B-BCE5-B32607570051","name":"edit"}
{
  "uptime" : 620000,
  "procRole" : "Foreground",
  "version" : 2,
  "userID" : 501,
  "deployVersion" : 210,
  "modelCode" : "MacBookPro17,1",
  "coalitionID" : 3546,
  "osVersion" : {
    "train" : "macOS 14.2.1",
    "build" : "23C71",
    "releaseType" : "User"
  },
  "captureTime" : "2025-03-25 22:11:15.4541 -0400",
  "codeSigningMonitor" : 1,
  "incident" : "112492B3-2740-434B-BCE5-B32607570051",
  "pid" : 97235,
  "translated" : false,
  "cpuType" : "ARM-64",
  "roots_installed" : 0,
  "bug_type" : "309",
  "procLaunch" : "2025-03-25 22:10:16.5493 -0400",
  "procStartAbsTime" : 15094039887149,
  "procExitAbsTime" : 15095452534843,
  "procName" : "edit",
  "procPath" : "\/Users\/USER\/Documents\/*\/edit",
  "parentProc" : "Exited process",
  "parentPid" : 97125,
  "coalitionName" : "com.github.wez.wezterm",
  "crashReporterKey" : "F03D0247-0FBD-2B4F-EE03-1472490A30EE",
  "responsiblePid" : 46218,
  "responsibleProc" : "wezterm-gui",
  "codeSigningID" : "edit",
  "codeSigningTeamID" : "",
  "codeSigningFlags" : 570556929,
  "codeSigningValidationCategory" : 10,
  "codeSigningTrustLevel" : 4294967295,
  "instructionByteStream" : {"beforePC":"4QMAqmjQO9UIeUD5AhVA+QABQPlfCB\/W4gMBquEDAKpo0DvVCHlA+Q==","atPC":"AxlA+QABQPl\/CB\/W4wMCquIDAarhAwCqaNA71Qh5QPkEHUD5AAFA+Q=="},
  "wakeTime" : 19146,
  "sleepWakeUUID" : "6969127B-6EB4-4A1E-AF3C-8F2C00500E34",
  "sip" : "enabled",
  "vmRegionInfo" : "0x30 is not in any region.  Bytes before following region: 4303355856\n      REGION TYPE                    START - END         [ VSIZE] PRT\/MAX SHRMOD  REGION DETAIL\n      UNUSED SPACE AT START\n--->  \n      __TEXT                      100800000-10083c000    [  240K] r-x\/r-x SM=COW  ...uments\/*\/edit",
  "exception" : {"codes":"0x0000000000000001, 0x0000000000000030","rawCodes":[1,48],"type":"EXC_BAD_ACCESS","signal":"SIGSEGV","subtype":"KERN_INVALID_ADDRESS at 0x0000000000000030"},
  "termination" : {"flags":0,"code":11,"namespace":"SIGNAL","indicator":"Segmentation fault: 11","byProc":"exc handler","byPid":97235},
  "vmregioninfo" : "0x30 is not in any region.  Bytes before following region: 4303355856\n      REGION TYPE                    START - END         [ VSIZE] PRT\/MAX SHRMOD  REGION DETAIL\n      UNUSED SPACE AT START\n--->  \n      __TEXT                      100800000-10083c000    [  240K] r-x\/r-x SM=COW  ...uments\/*\/edit",
  "extMods" : {"caller":{"thread_create":0,"thread_set_state":0,"task_for_pid":0},"system":{"thread_create":0,"thread_set_state":0,"task_for_pid":0},"targeted":{"thread_create":0,"thread_set_state":0,"task_for_pid":0},"warnings":0},
  "faultingThread" : 11,
  "threads" : [{"id":8456223,"threadState":{"x":[{"value":6163521200},{"value":4303585971},{"value":4282201405},{"value":12},{"value":4785074608363353405},{"value":4282201405},{"value":49},{"value":0},{"value":3},{"value":4303585976},{"value":0},{"value":4310801216,"symbolLocation":0,"symbol":"defaultFont"},{"value":72},{"value":49},{"value":5738298880},{"value":5738298880},{"value":4310312948,"symbolLocation":0,"symbol":"DrawText"},{"value":8268266512},{"value":0},{"value":4303585971},{"value":6163521200},{"value":6163525536},{"value":4308015376},{"value":6163525664},{"value":6163525728},{"value":6662555115},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":4310313060},"cpsr":{"value":536875008},"fp":{"value":6163521184},"sp":{"value":6163520976},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":4310313368},"far":{"value":0}},"queue":"com.apple.main-thread","frames":[{"imageOffset":633240,"symbol":"DrawTextEx","symbolLocation":144,"imageIndex":4},{"imageOffset":632932,"symbol":"DrawText","symbolLocation":112,"imageIndex":4},{"imageOffset":632932,"symbol":"DrawText","symbolLocation":112,"imageIndex":4},{"imageOffset":125072,"symbol":"tpp_method_Drawer_Text","symbolLocation":84,"imageIndex":70},{"imageOffset":56336,"symbol":"ElementTimelineUI","symbolLocation":1868,"imageIndex":70},{"imageOffset":49864,"symbol":"GameTick","symbolLocation":2060,"imageIndex":70},{"imageOffset":46572,"symbol":"main","symbolLocation":4188,"imageIndex":70},{"imageOffset":24800,"symbol":"start","symbolLocation":2360,"imageIndex":71}]},{"id":8456237,"frames":[{"imageOffset":7720,"symbol":"start_wqthread","symbolLocation":0,"imageIndex":73}],"threadState":{"x":[{"value":6164656128},{"value":5127},{"value":6164119552},{"value":0},{"value":409604},{"value":18446744073709551615},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":0},"cpsr":{"value":4096},"fp":{"value":0},"sp":{"value":6164656128},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6665686568},"far":{"value":0}}},{"id":8456238,"frames":[{"imageOffset":7720,"symbol":"start_wqthread","symbolLocation":0,"imageIndex":73}],"threadState":{"x":[{"value":6164082688},{"value":8707},{"value":6163546112},{"value":0},{"value":409604},{"value":18446744073709551615},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":0},"cpsr":{"value":4096},"fp":{"value":0},"sp":{"value":6164082688},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6665686568},"far":{"value":0}}},{"id":8456269,"name":"com.apple.NSEventThread","threadState":{"x":[{"value":268451845},{"value":21592279046},{"value":8589934592},{"value":118760140701696},{"value":0},{"value":118760140701696},{"value":2},{"value":4294967295},{"value":18446744073709550527},{"value":27651},{"value":0},{"value":1},{"value":27651},{"value":166817},{"value":0},{"value":0},{"value":18446744073709551569},{"value":8268248528},{"value":0},{"value":4294967295},{"value":2},{"value":118760140701696},{"value":0},{"value":118760140701696},{"value":6165225576},{"value":8589934592},{"value":21592279046},{"value":21592279046},{"value":4412409862}],"flavor":"ARM_THREAD_STATE64","lr":{"value":6665518320},"cpsr":{"value":4096},"fp":{"value":6165225424},"sp":{"value":6165225344},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6665443444},"far":{"value":0}},"frames":[{"imageOffset":6260,"symbol":"mach_msg2_trap","symbolLocation":8,"imageIndex":74},{"imageOffset":81136,"symbol":"mach_msg2_internal","symbolLocation":80,"imageIndex":74},{"imageOffset":42160,"symbol":"mach_msg_overwrite","symbolLocation":476,"imageIndex":74},{"imageOffset":7160,"symbol":"mach_msg","symbolLocation":24,"imageIndex":74},{"imageOffset":515060,"symbol":"__CFRunLoopServiceMachPort","symbolLocation":160,"imageIndex":75},{"imageOffset":509116,"symbol":"__CFRunLoopRun","symbolLocation":1208,"imageIndex":75},{"imageOffset":506284,"symbol":"CFRunLoopRunSpecific","symbolLocation":608,"imageIndex":75},{"imageOffset":1455376,"symbol":"_NSEventThread","symbolLocation":144,"imageIndex":76},{"imageOffset":28724,"symbol":"_pthread_start","symbolLocation":136,"imageIndex":73},{"imageOffset":7740,"symbol":"thread_start","symbolLocation":8,"imageIndex":73}]},{"id":8456271,"frames":[{"imageOffset":7720,"symbol":"start_wqthread","symbolLocation":0,"imageIndex":73}],"threadState":{"x":[{"value":6165803008},{"value":61455},{"value":6165266432},{"value":0},{"value":409604},{"value":18446744073709551615},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":0},"cpsr":{"value":4096},"fp":{"value":0},"sp":{"value":6165803008},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6665686568},"far":{"value":0}}},{"id":8456284,"name":"caulk.messenger.shared:17","threadState":{"x":[{"value":14},{"value":105553122398458},{"value":0},{"value":6166376554},{"value":105553122398432},{"value":25},{"value":0},{"value":0},{"value":0},{"value":4294967295},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":18446744073709551580},{"value":8268254024},{"value":0},{"value":105553182262320},{"value":105553182262320},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":6837175952},"cpsr":{"value":2147487744},"fp":{"value":6166376320},"sp":{"value":6166376288},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6665443312},"far":{"value":0}},"frames":[{"imageOffset":6128,"symbol":"semaphore_wait_trap","symbolLocation":8,"imageIndex":74},{"imageOffset":9872,"symbol":"caulk::semaphore::timed_wait(double)","symbolLocation":212,"imageIndex":77},{"imageOffset":9540,"symbol":"caulk::concurrent::details::worker_thread::run()","symbolLocation":36,"imageIndex":77},{"imageOffset":8772,"symbol":"void* caulk::thread_proxy<std::__1::tuple<caulk::thread::attributes, void (caulk::concurrent::details::worker_thread::*)(), std::__1::tuple<caulk::concurrent::details::worker_thread*>>>(void*)","symbolLocation":96,"imageIndex":77},{"imageOffset":28724,"symbol":"_pthread_start","symbolLocation":136,"imageIndex":73},{"imageOffset":7740,"symbol":"thread_start","symbolLocation":8,"imageIndex":73}]},{"id":8456285,"name":"caulk.messenger.shared:high","threadState":{"x":[{"value":14},{"value":49155},{"value":49155},{"value":11},{"value":4294967295},{"value":0},{"value":0},{"value":0},{"value":0},{"value":4294967295},{"value":1},{"value":105553128672072},{"value":0},{"value":0},{"value":0},{"value":0},{"value":18446744073709551580},{"value":8268254024},{"value":0},{"value":105553182297168},{"value":105553182297168},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":6837175952},"cpsr":{"value":2147487744},"fp":{"value":6166949760},"sp":{"value":6166949728},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6665443312},"far":{"value":0}},"frames":[{"imageOffset":6128,"symbol":"semaphore_wait_trap","symbolLocation":8,"imageIndex":74},{"imageOffset":9872,"symbol":"caulk::semaphore::timed_wait(double)","symbolLocation":212,"imageIndex":77},{"imageOffset":9540,"symbol":"caulk::concurrent::details::worker_thread::run()","symbolLocation":36,"imageIndex":77},{"imageOffset":8772,"symbol":"void* caulk::thread_proxy<std::__1::tuple<caulk::thread::attributes, void (caulk::concurrent::details::worker_thread::*)(), std::__1::tuple<caulk::concurrent::details::worker_thread*>>>(void*)","symbolLocation":96,"imageIndex":77},{"imageOffset":28724,"symbol":"_pthread_start","symbolLocation":136,"imageIndex":73},{"imageOffset":7740,"symbol":"thread_start","symbolLocation":8,"imageIndex":73}]},{"id":8456336,"name":"caulk::deferred_logger","threadState":{"x":[{"value":14},{"value":105553151875575},{"value":0},{"value":6167523431},{"value":105553151875552},{"value":22},{"value":0},{"value":0},{"value":0},{"value":4294967295},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":18446744073709551580},{"value":8268254024},{"value":0},{"value":105553180181656},{"value":105553180181656},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":6837175952},"cpsr":{"value":2147487744},"fp":{"value":6167523200},"sp":{"value":6167523168},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6665443312},"far":{"value":0}},"frames":[{"imageOffset":6128,"symbol":"semaphore_wait_trap","symbolLocation":8,"imageIndex":74},{"imageOffset":9872,"symbol":"caulk::semaphore::timed_wait(double)","symbolLocation":212,"imageIndex":77},{"imageOffset":9540,"symbol":"caulk::concurrent::details::worker_thread::run()","symbolLocation":36,"imageIndex":77},{"imageOffset":8772,"symbol":"void* caulk::thread_proxy<std::__1::tuple<caulk::thread::attributes, void (caulk::concurrent::details::worker_thread::*)(), std::__1::tuple<caulk::concurrent::details::worker_thread*>>>(void*)","symbolLocation":96,"imageIndex":77},{"imageOffset":28724,"symbol":"_pthread_start","symbolLocation":136,"imageIndex":73},{"imageOffset":7740,"symbol":"thread_start","symbolLocation":8,"imageIndex":73}]},{"id":8456338,"name":"com.apple.audio.IOThread.client","threadState":{"x":[{"value":268451845},{"value":17179869187},{"value":103079215123},{"value":90627},{"value":25078314041344},{"value":385941466251264},{"value":32},{"value":0},{"value":18446744073709550527},{"value":89859},{"value":5839},{"value":1},{"value":89859},{"value":0},{"value":4675227456},{"value":4670636992},{"value":18446744073709551569},{"value":8268248528},{"value":0},{"value":0},{"value":32},{"value":385941466251264},{"value":25078314041344},{"value":90627},{"value":6168095952},{"value":103079215123},{"value":17179869187},{"value":17179869187},{"value":3}],"flavor":"ARM_THREAD_STATE64","lr":{"value":6665518320},"cpsr":{"value":536875008},"fp":{"value":6168095616},"sp":{"value":6168095536},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6665443444},"far":{"value":0}},"frames":[{"imageOffset":6260,"symbol":"mach_msg2_trap","symbolLocation":8,"imageIndex":74},{"imageOffset":81136,"symbol":"mach_msg2_internal","symbolLocation":80,"imageIndex":74},{"imageOffset":42160,"symbol":"mach_msg_overwrite","symbolLocation":476,"imageIndex":74},{"imageOffset":7160,"symbol":"mach_msg","symbolLocation":24,"imageIndex":74},{"imageOffset":3226784,"symbol":"HALB_MachPort::SendSimpleMessageWithSimpleReply(unsigned int, unsigned int, int, int&, bool, unsigned int)","symbolLocation":96,"imageIndex":78},{"imageOffset":2009988,"symbol":"HALC_ProxyIOContext::IOWorkLoop()","symbolLocation":4260,"imageIndex":78},{"imageOffset":2003888,"symbol":"invocation function for block in HALC_ProxyIOContext::HALC_ProxyIOContext(unsigned int, unsigned int)","symbolLocation":108,"imageIndex":78},{"imageOffset":3573092,"symbol":"HALC_IOThread::Entry(void*)","symbolLocation":88,"imageIndex":78},{"imageOffset":28724,"symbol":"_pthread_start","symbolLocation":136,"imageIndex":73},{"imageOffset":7740,"symbol":"thread_start","symbolLocation":8,"imageIndex":73}]},{"id":8456365,"frames":[{"imageOffset":7720,"symbol":"start_wqthread","symbolLocation":0,"imageIndex":73}],"threadState":{"x":[{"value":6168670208},{"value":100911},{"value":6168133632},{"value":0},{"value":409604},{"value":18446744073709551615},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":0},"cpsr":{"value":4096},"fp":{"value":0},"sp":{"value":6168670208},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6665686568},"far":{"value":0}}},{"id":8456414,"frames":[{"imageOffset":7720,"symbol":"start_wqthread","symbolLocation":0,"imageIndex":73}],"threadState":{"x":[{"value":6169243648},{"value":91155},{"value":6168707072},{"value":0},{"value":409604},{"value":18446744073709551615},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":0},"cpsr":{"value":4096},"fp":{"value":0},"sp":{"value":6169243648},"esr":{"value":1442840704,"description":" Address size fault"},"pc":{"value":6665686568},"far":{"value":0}}},{"triggered":true,"id":8457327,"threadState":{"x":[{"value":3553},{"value":3553},{"value":3},{"value":7},{"value":6169817088},{"value":419432703},{"value":0},{"value":0},{"value":0},{"value":6169816680},{"value":3101722017635041516},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0},{"value":4310365348,"symbolLocation":0,"symbol":"LoadImageFromTexture"},{"value":8268264400},{"value":0},{"value":7},{"value":3},{"value":900},{"value":1200},{"value":4310814720,"symbolLocation":64,"symbol":"_glfwMainThreadError"},{"value":0},{"value":0},{"value":0},{"value":0},{"value":0}],"flavor":"ARM_THREAD_STATE64","lr":{"value":4310036668},"cpsr":{"value":2147487744},"fp":{"value":6169816352},"sp":{"value":6169816272},"esr":{"value":2449473542,"description":"(Data Abort) byte read Translation fault"},"pc":{"value":8419776760,"matchesCrashFrame":1},"far":{"value":48}},"frames":[{"imageOffset":2296,"symbol":"glBindTexture","symbolLocation":16,"imageIndex":79},{"imageOffset":356540,"symbol":"rlReadTexturePixels","symbolLocation":60,"imageIndex":4},{"imageOffset":685276,"symbol":"LoadImageFromTexture","symbolLocation":56,"imageIndex":4},{"imageOffset":59836,"symbol":"ExportVideo","symbolLocation":88,"imageIndex":70},{"imageOffset":59720,"symbol":"ExportVideoThread","symbolLocation":40,"imageIndex":70},{"imageOffset":28724,"symbol":"_pthread_start","symbolLocation":136,"imageIndex":73},{"imageOffset":7740,"symbol":"thread_start","symbolLocation":8,"imageIndex":73}]}],
  "usedImages" : [
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 4673716224,
    "CFBundleShortVersionString" : "1.14",
    "CFBundleIdentifier" : "com.apple.audio.units.Components",
    "size" : 1277952,
    "uuid" : "06275638-4d71-370d-bf96-b30a567270e1",
    "path" : "\/System\/Library\/Components\/CoreAudio.component\/Contents\/MacOS\/CoreAudio",
    "name" : "CoreAudio",
    "CFBundleVersion" : "1.14"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 4392828928,
    "CFBundleShortVersionString" : "1.0",
    "CFBundleIdentifier" : "com.apple.AppleMetalOpenGLRenderer",
    "size" : 442368,
    "uuid" : "41cb4d99-6a07-366a-9e97-d047ce10daa2",
    "path" : "\/System\/Library\/Extensions\/AppleMetalOpenGLRenderer.bundle\/Contents\/MacOS\/AppleMetalOpenGLRenderer",
    "name" : "AppleMetalOpenGLRenderer",
    "CFBundleVersion" : "1"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 4358602752,
    "size" : 49152,
    "uuid" : "7778e0d7-361a-378d-9438-3b2bb48c2154",
    "path" : "\/usr\/lib\/libobjc-trampolines.dylib",
    "name" : "libobjc-trampolines.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4303978496,
    "size" : 81920,
    "uuid" : "c864d4a5-e7a1-3527-976b-8ea179daadf4",
    "path" : "\/Users\/USER\/Documents\/*\/libscript.dylib",
    "name" : "libscript.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4309680128,
    "size" : 1064960,
    "uuid" : "04958d5f-6d60-33ea-a976-f5919f8313f8",
    "path" : "\/opt\/homebrew\/*\/libraylib.5.5.0.dylib",
    "name" : "libraylib.5.5.0.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4321378304,
    "size" : 9568256,
    "uuid" : "6a122518-7dcc-316f-875e-ae7f2b09222f",
    "path" : "\/opt\/homebrew\/*\/libavcodec.61.19.100.dylib",
    "name" : "libavcodec.61.19.100.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4313497600,
    "size" : 1998848,
    "uuid" : "59b4d0b8-63ca-3178-9dea-4a2355c2d142",
    "path" : "\/opt\/homebrew\/*\/libavformat.61.7.100.dylib",
    "name" : "libavformat.61.7.100.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4337647616,
    "size" : 475136,
    "uuid" : "9e2c663b-35ee-3078-8f6b-c0059eeeae5f",
    "path" : "\/opt\/homebrew\/*\/libavutil.59.39.100.dylib",
    "name" : "libavutil.59.39.100.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4308746240,
    "size" : 393216,
    "uuid" : "5bf08f2a-b2e3-337d-a774-867032d3604c",
    "path" : "\/opt\/homebrew\/*\/libswscale.8.3.100.dylib",
    "name" : "libswscale.8.3.100.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4308418560,
    "size" : 81920,
    "uuid" : "19aa942c-c213-3eff-8213-efae88154340",
    "path" : "\/opt\/homebrew\/*\/libswresample.5.3.100.dylib",
    "name" : "libswresample.5.3.100.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4315856896,
    "size" : 1523712,
    "uuid" : "0ad3c1cf-cb22-3842-aaa4-293bf557c97a",
    "path" : "\/opt\/homebrew\/*\/libvpx.9.dylib",
    "name" : "libvpx.9.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4308549632,
    "size" : 32768,
    "uuid" : "a18155e2-fd5b-3735-9604-f964f0ab8683",
    "path" : "\/opt\/homebrew\/*\/libwebpmux.3.1.0.dylib",
    "name" : "libwebpmux.3.1.0.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4309434368,
    "size" : 131072,
    "uuid" : "131a4891-8890-3954-97e3-78c25a374e98",
    "path" : "\/opt\/homebrew\/*\/liblzma.5.dylib",
    "name" : "liblzma.5.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4308631552,
    "size" : 65536,
    "uuid" : "ad2f19ff-f755-3588-93ca-3e3025243524",
    "path" : "\/opt\/homebrew\/*\/libaribb24.0.dylib",
    "name" : "libaribb24.0.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4311941120,
    "size" : 622592,
    "uuid" : "0320d976-fc09-3758-95af-f72e7d760916",
    "path" : "\/opt\/homebrew\/*\/libdav1d.7.dylib",
    "name" : "libdav1d.7.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4309237760,
    "size" : 65536,
    "uuid" : "b385f9c0-2a73-3648-976d-a34f41304f46",
    "path" : "\/opt\/homebrew\/*\/libopencore-amrwb.0.dylib",
    "name" : "libopencore-amrwb.0.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4311138304,
    "size" : 32768,
    "uuid" : "2e01fa4f-06ab-327c-b0ce-4b0a0931e5b3",
    "path" : "\/opt\/homebrew\/*\/libsnappy.1.2.1.dylib",
    "name" : "libsnappy.1.2.1.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4359208960,
    "size" : 3538944,
    "uuid" : "f662f185-80b8-3f8c-bf61-5315a885456d",
    "path" : "\/opt\/homebrew\/*\/libaom.3.11.0.dylib",
    "name" : "libaom.3.11.0.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4318380032,
    "size" : 163840,
    "uuid" : "7ef169d5-d3ae-3a2e-90fe-0b633c6ccf99",
    "path" : "\/opt\/homebrew\/*\/libvmaf.3.dylib",
    "name" : "libvmaf.3.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4355129344,
    "size" : 1376256,
    "uuid" : "f0839603-0586-37af-9de9-147772ced9f6",
    "path" : "\/opt\/homebrew\/*\/libjxl.0.11.1.dylib",
    "name" : "libjxl.0.11.1.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4308353024,
    "size" : 16384,
    "uuid" : "16d7ae78-47cc-3e05-aa73-f5ab4757d1b7",
    "path" : "\/opt\/homebrew\/*\/libjxl_threads.0.11.1.dylib",
    "name" : "libjxl_threads.0.11.1.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4312973312,
    "size" : 229376,
    "uuid" : "68e5cf9a-d53f-3676-842f-ebc85f005698",
    "path" : "\/opt\/homebrew\/*\/libmp3lame.0.dylib",
    "name" : "libmp3lame.0.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4311416832,
    "size" : 131072,
    "uuid" : "4f75e4c3-734d-3dc9-8a39-9fadb7a09d38",
    "path" : "\/opt\/homebrew\/*\/libopencore-amrnb.0.dylib",
    "name" : "libopencore-amrnb.0.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4317626368,
    "size" : 262144,
    "uuid" : "909347a2-9b4d-3a68-bea0-1754ce12e3ce",
    "path" : "\/opt\/homebrew\/*\/libopenjp2.2.5.3.dylib",
    "name" : "libopenjp2.2.5.3.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4319395840,
    "size" : 294912,
    "uuid" : "20f4d666-162c-30c8-88e0-c962e1faacdf",
    "path" : "\/opt\/homebrew\/*\/libopus.0.dylib",
    "name" : "libopus.0.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4366401536,
    "size" : 1966080,
    "uuid" : "36de9c5f-9d32-3e23-a529-a9cd2f35182a",
    "path" : "\/opt\/homebrew\/*\/librav1e.0.7.1.dylib",
    "name" : "librav1e.0.7.1.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4311613440,
    "size" : 81920,
    "uuid" : "546d9e85-d9f2-3a01-a64a-77307884d24a",
    "path" : "\/opt\/homebrew\/*\/libspeex.1.dylib",
    "name" : "libspeex.1.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4372054016,
    "size" : 2490368,
    "uuid" : "58566809-7a99-3e27-97f0-537120e21930",
    "path" : "\/opt\/homebrew\/*\/libSvtAv1Enc.2.2.0.dylib",
    "name" : "libSvtAv1Enc.2.2.0.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4319756288,
    "size" : 147456,
    "uuid" : "22c1a2e4-e4e0-3f0b-a401-f27730148761",
    "path" : "\/opt\/homebrew\/*\/libtheoraenc.1.dylib",
    "name" : "libtheoraenc.1.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4311760896,
    "size" : 49152,
    "uuid" : "a03d1876-ebc8-3326-b48a-7e46189cb986",
    "path" : "\/opt\/homebrew\/*\/libtheoradec.1.dylib",
    "name" : "libtheoradec.1.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4311318528,
    "size" : 32768,
    "uuid" : "7343af8b-ee18-3518-ac9e-86729a8083ef",
    "path" : "\/opt\/homebrew\/*\/libogg.0.dylib",
    "name" : "libogg.0.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4319969280,
    "size" : 147456,
    "uuid" : "edb49fa1-7896-3e7f-8b16-813fc1b05112",
    "path" : "\/opt\/homebrew\/*\/libvorbis.0.dylib",
    "name" : "libvorbis.0.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4357111808,
    "size" : 491520,
    "uuid" : "2664b493-7704-3fd9-a41f-9fe10b9dfb62",
    "path" : "\/opt\/homebrew\/*\/libvorbisenc.2.dylib",
    "name" : "libvorbisenc.2.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4320182272,
    "size" : 262144,
    "uuid" : "b244e1ca-e3fe-3897-a0a3-d14ed220a88b",
    "path" : "\/opt\/homebrew\/*\/libwebp.7.1.9.dylib",
    "name" : "libwebp.7.1.9.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4363599872,
    "size" : 1196032,
    "uuid" : "cdbfaf38-a184-31fe-abd6-7ff7ddf2f0ef",
    "path" : "\/opt\/homebrew\/*\/libx264.164.dylib",
    "name" : "libx264.164.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4380999680,
    "size" : 3522560,
    "uuid" : "00683954-7bb2-39f5-ab69-c1ef0d374e5d",
    "path" : "\/opt\/homebrew\/*\/libx265.212.dylib",
    "name" : "libx265.212.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4320542720,
    "size" : 131072,
    "uuid" : "f0c93f6f-447e-3469-a155-47bf9611e4b7",
    "path" : "\/opt\/homebrew\/*\/libsoxr.0.1.2.dylib",
    "name" : "libsoxr.0.1.2.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4369203200,
    "size" : 868352,
    "uuid" : "2a4ca82f-7c9e-3814-9840-4fe71cb271d2",
    "path" : "\/opt\/homebrew\/*\/libX11.6.dylib",
    "name" : "libX11.6.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4318167040,
    "size" : 81920,
    "uuid" : "8ef9b9ff-3f1e-39a6-bec1-e7d10db8e6cb",
    "path" : "\/opt\/homebrew\/*\/libxcb.1.1.0.dylib",
    "name" : "libxcb.1.1.0.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4317970432,
    "size" : 16384,
    "uuid" : "52eda2b7-12f8-3daa-888b-d615e658c4f0",
    "path" : "\/opt\/homebrew\/*\/libXau.6.0.0.dylib",
    "name" : "libXau.6.0.0.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4309368832,
    "size" : 16384,
    "uuid" : "11368a67-e3a3-3d6f-ae03-78456881a92e",
    "path" : "\/opt\/homebrew\/*\/libXdmcp.6.dylib",
    "name" : "libXdmcp.6.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4318052352,
    "size" : 16384,
    "uuid" : "62623b16-60a4-32f6-81a4-585016484956",
    "path" : "\/opt\/homebrew\/*\/libsharpyuv.0.1.0.dylib",
    "name" : "libsharpyuv.0.1.0.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4321165312,
    "size" : 147456,
    "uuid" : "f00fd0e9-dac7-3ef5-bd8f-a4b5f3a57dd1",
    "path" : "\/opt\/homebrew\/*\/libpng16.16.dylib",
    "name" : "libpng16.16.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4357849088,
    "size" : 49152,
    "uuid" : "94cae2b8-9af4-3162-8135-39c184af4cbb",
    "path" : "\/opt\/homebrew\/*\/libjxl_cms.0.11.1.dylib",
    "name" : "libjxl_cms.0.11.1.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4320952320,
    "size" : 32768,
    "uuid" : "35666841-18ae-32b3-a37b-d33d3c347610",
    "path" : "\/opt\/homebrew\/*\/libhwy.1.2.0.dylib",
    "name" : "libhwy.1.2.0.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4321050624,
    "size" : 49152,
    "uuid" : "2b673811-9400-3f1c-8ec0-d2a7d4b75e2c",
    "path" : "\/opt\/homebrew\/*\/libbrotlidec.1.1.0.dylib",
    "name" : "libbrotlidec.1.1.0.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4358144000,
    "size" : 131072,
    "uuid" : "d6d17b55-1cd9-3744-8d06-c9990225fa39",
    "path" : "\/opt\/homebrew\/*\/libbrotlicommon.1.1.0.dylib",
    "name" : "libbrotlicommon.1.1.0.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4370235392,
    "size" : 573440,
    "uuid" : "9c06eacb-6f5c-3267-a89a-39103dc342fc",
    "path" : "\/opt\/homebrew\/*\/libbrotlienc.1.1.0.dylib",
    "name" : "libbrotlienc.1.1.0.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4358684672,
    "size" : 245760,
    "uuid" : "e7a6ea33-e47c-3548-90d4-1eed45091886",
    "path" : "\/opt\/homebrew\/*\/liblcms2.2.dylib",
    "name" : "liblcms2.2.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4365926400,
    "size" : 262144,
    "uuid" : "26c4f6f7-5d39-3c12-831a-a852dc21c318",
    "path" : "\/opt\/homebrew\/*\/libbluray.2.dylib",
    "name" : "libbluray.2.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4378132480,
    "size" : 1523712,
    "uuid" : "59e2dd5f-5401-3d77-8546-4e94b8552035",
    "path" : "\/opt\/homebrew\/*\/libgnutls.30.dylib",
    "name" : "libgnutls.30.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4370890752,
    "size" : 114688,
    "uuid" : "36312e14-9b42-3cbb-a86a-c7c01c736022",
    "path" : "\/opt\/homebrew\/*\/librist.4.dylib",
    "name" : "librist.4.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4376248320,
    "size" : 458752,
    "uuid" : "f9e45ab1-72ef-3d68-b946-46b5dd512dd7",
    "path" : "\/opt\/homebrew\/*\/libsrt.1.5.4.dylib",
    "name" : "libsrt.1.5.4.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4376969216,
    "size" : 344064,
    "uuid" : "56d71248-3350-3760-99eb-3f50efe86eb8",
    "path" : "\/opt\/homebrew\/*\/libssh.4.10.1.dylib",
    "name" : "libssh.4.10.1.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4377460736,
    "size" : 360448,
    "uuid" : "8f363bb6-d8b9-3179-b0b7-e1914a93eea9",
    "path" : "\/opt\/homebrew\/*\/libzmq.5.dylib",
    "name" : "libzmq.5.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4371087360,
    "size" : 212992,
    "uuid" : "99ce4547-5924-35e1-aa62-6f1d4a8289cd",
    "path" : "\/opt\/homebrew\/*\/libfontconfig.1.dylib",
    "name" : "libfontconfig.1.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4380033024,
    "size" : 507904,
    "uuid" : "26d566c1-3b1f-30fb-ba97-0413177dae5e",
    "path" : "\/opt\/homebrew\/*\/libfreetype.6.dylib",
    "name" : "libfreetype.6.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4358324224,
    "size" : 98304,
    "uuid" : "9924fd2d-8556-34b2-add9-ab2838b3359b",
    "path" : "\/opt\/homebrew\/*\/libintl.8.dylib",
    "name" : "libintl.8.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4387291136,
    "size" : 1015808,
    "uuid" : "5ab305be-ee60-302b-a5e4-2b42f5ea5103",
    "path" : "\/opt\/homebrew\/*\/libp11-kit.0.dylib",
    "name" : "libp11-kit.0.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4371660800,
    "size" : 196608,
    "uuid" : "a980ce71-e631-397d-a451-452a3a0be6ec",
    "path" : "\/opt\/homebrew\/*\/libidn2.0.dylib",
    "name" : "libidn2.0.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4390797312,
    "size" : 1884160,
    "uuid" : "e8557d4d-ca9a-3119-bee5-b246473a46c0",
    "path" : "\/opt\/homebrew\/*\/libunistring.5.dylib",
    "name" : "libunistring.5.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4358488064,
    "size" : 49152,
    "uuid" : "799845d9-7beb-30fa-89ea-542d4e6d2590",
    "path" : "\/opt\/homebrew\/*\/libtasn1.6.dylib",
    "name" : "libtasn1.6.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4386160640,
    "size" : 229376,
    "uuid" : "35ded263-acb6-333d-91c3-c2e07cfecca3",
    "path" : "\/opt\/homebrew\/*\/libnettle.8.9.dylib",
    "name" : "libnettle.8.9.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4386504704,
    "size" : 245760,
    "uuid" : "c360b13b-689f-3ac7-b03d-b6f5d40ec43c",
    "path" : "\/opt\/homebrew\/*\/libhogweed.6.9.dylib",
    "name" : "libhogweed.6.9.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4388765696,
    "size" : 360448,
    "uuid" : "f6a7b957-4314-3ea5-ac52-39a649bd3a58",
    "path" : "\/opt\/homebrew\/*\/libgmp.10.dylib",
    "name" : "libgmp.10.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4389748736,
    "size" : 344064,
    "uuid" : "fa46eba9-6fb7-3b1f-95b1-6070d4230fa8",
    "path" : "\/opt\/homebrew\/*\/libmbedcrypto.3.6.2.dylib",
    "name" : "libmbedcrypto.3.6.2.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4357963776,
    "size" : 16384,
    "uuid" : "f02fe1c5-1dce-387a-a4e2-d6f37957fe4c",
    "path" : "\/opt\/homebrew\/*\/libcjson.1.7.18.dylib",
    "name" : "libcjson.1.7.18.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4393697280,
    "size" : 573440,
    "uuid" : "97f508a8-5334-38d1-add5-2d786550cdb3",
    "path" : "\/opt\/homebrew\/*\/libssl.3.dylib",
    "name" : "libssl.3.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4398891008,
    "size" : 3096576,
    "uuid" : "ec558165-eb5e-35a2-8fe0-aa335b3fed24",
    "path" : "\/opt\/homebrew\/*\/libcrypto.3.dylib",
    "name" : "libcrypto.3.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4385816576,
    "size" : 180224,
    "uuid" : "56c8d86f-7358-3639-8b41-7605cb5e8c7c",
    "path" : "\/opt\/homebrew\/*\/libsodium.26.dylib",
    "name" : "libsodium.26.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64",
    "base" : 4303355904,
    "size" : 245760,
    "uuid" : "d312573b-b559-353d-9509-076f0ceb5bc8",
    "path" : "\/Users\/USER\/Documents\/*\/edit",
    "name" : "edit"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 6662008832,
    "size" : 607048,
    "uuid" : "324e4ad9-e01f-3183-b09f-3e20b326643a",
    "path" : "\/usr\/lib\/dyld",
    "name" : "dyld"
  },
  {
    "size" : 0,
    "source" : "A",
    "base" : 0,
    "uuid" : "00000000-0000-0000-0000-000000000000"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 6665678848,
    "size" : 53236,
    "uuid" : "a7d94c96-7b1f-3229-9bea-048d037c3292",
    "path" : "\/usr\/lib\/system\/libsystem_pthread.dylib",
    "name" : "libsystem_pthread.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 6665437184,
    "size" : 241664,
    "uuid" : "ca94fc21-bc40-3b43-b65d-b87ece9e1d48",
    "path" : "\/usr\/lib\/system\/libsystem_kernel.dylib",
    "name" : "libsystem_kernel.dylib"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 6666100736,
    "CFBundleShortVersionString" : "6.9",
    "CFBundleIdentifier" : "com.apple.CoreFoundation",
    "size" : 5079040,
    "uuid" : "47e4ec09-8f6e-30a8-99d0-34024d4f8122",
    "path" : "\/System\/Library\/Frameworks\/CoreFoundation.framework\/Versions\/A\/CoreFoundation",
    "name" : "CoreFoundation",
    "CFBundleVersion" : "2202"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 6724947968,
    "CFBundleShortVersionString" : "6.9",
    "CFBundleIdentifier" : "com.apple.AppKit",
    "size" : 20033536,
    "uuid" : "f3527312-e426-3f7c-b77b-2bf49d1b7c04",
    "path" : "\/System\/Library\/Frameworks\/AppKit.framework\/Versions\/C\/AppKit",
    "name" : "AppKit",
    "CFBundleVersion" : "2487.30.108"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 6837166080,
    "CFBundleShortVersionString" : "1.0",
    "CFBundleIdentifier" : "com.apple.audio.caulk",
    "size" : 172032,
    "uuid" : "25e50b84-b506-3db7-9a91-3824b9b8b880",
    "path" : "\/System\/Library\/PrivateFrameworks\/caulk.framework\/Versions\/A\/caulk",
    "name" : "caulk"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 6705774592,
    "CFBundleShortVersionString" : "5.0",
    "CFBundleIdentifier" : "com.apple.audio.CoreAudio",
    "size" : 7286784,
    "uuid" : "2c54c60c-a5af-39f4-8286-0cb88fa43367",
    "path" : "\/System\/Library\/Frameworks\/CoreAudio.framework\/Versions\/A\/CoreAudio",
    "name" : "CoreAudio",
    "CFBundleVersion" : "5.0"
  },
  {
    "source" : "P",
    "arch" : "arm64e",
    "base" : 8419774464,
    "size" : 40960,
    "uuid" : "92b8b37d-0c5d-3f98-aede-56df6d84ae1f",
    "path" : "\/System\/Library\/Frameworks\/OpenGL.framework\/Versions\/A\/Libraries\/libGL.dylib",
    "name" : "libGL.dylib"
  }
],
  "sharedCache" : {
  "base" : 6661259264,
  "size" : 4061216768,
  "uuid" : "f9ddd844-7f3f-34bd-be29-f0c72d5e5449"
},
  "vmSummary" : "ReadOnly portion of Libraries: Total=1.3G resident=0K(0%) swapped_out_or_unallocated=1.3G(100%)\nWritable regions: Total=2.6G written=0K(0%) resident=0K(0%) swapped_out=0K(0%) unallocated=2.6G(100%)\n\n                                VIRTUAL   REGION \nREGION TYPE                        SIZE    COUNT (non-coalesced) \n===========                     =======  ======= \nAccelerate framework               128K        1 \nActivity Tracing                   256K        1 \nCG image                            96K        5 \nColorSync                          592K       29 \nCoreAnimation                      496K       31 \nCoreGraphics                        48K        3 \nCoreUI image data                  528K        7 \nFoundation                          16K        1 \nKernel Alloc Once                   32K        1 \nMALLOC                             2.5G       65 \nMALLOC guard page                  192K       12 \nOpenGL GLSL                        256K        3 \nSTACK GUARD                       56.2M       12 \nStack                             13.8M       12 \nVM_ALLOCATE                       1872K       28 \nVM_ALLOCATE (reserved)              32K        1         reserved VM address space (unallocated)\n__AUTH                            1017K      226 \n__AUTH_CONST                      17.5M      403 \n__CTF                               824        1 \n__DATA                            30.8M      460 \n__DATA_CONST                      22.0M      477 \n__DATA_DIRTY                      1036K      127 \n__FONT_DATA                          4K        1 \n__GLSLBUILTINS                    5174K        1 \n__LINKEDIT                       900.5M       72 \n__OBJC_RO                         71.1M        1 \n__OBJC_RW                         2168K        1 \n__TEXT                           409.0M      491 \ndyld private memory                272K        2 \nmapped file                      181.9M       25 \nshared memory                      944K       15 \n===========                     =======  ======= \nTOTAL                              4.2G     2515 \nTOTAL, minus reserved VM space     4.2G     2515 \n",
  "legacyInfo" : {
  "threadTriggered" : {

  }
},
  "logWritingSignature" : "e181b4ec94a339a13668553c0414841f0ca5ed26",
  "trialInfo" : {
  "rollouts" : [
    {
      "rolloutId" : "632e3df958740028737bffc0",
      "factorPackIds" : {
        "SIRI_UNDERSTANDING_NL_OVERRIDES" : "661e78a3b714bf7f73d2b29e"
      },
      "deploymentId" : 240000670
    },
    {
      "rolloutId" : "5f72dc58705eff005a46b3a9",
      "factorPackIds" : {

      },
      "deploymentId" : 240000015
    }
  ],
  "experiments" : [

  ]
}
}

Model: MacBookPro17,1, BootROM 10151.61.4, proc 8:4:4 processors, 16 GB, SMC 
Graphics: Apple M1, Apple M1, Built-In
Display: ROG PG279Q, 2560 x 1440 (QHD/WQHD - Wide Quad High Definition), Main, MirrorOff, Online
Display: Color LCD, 2560 x 1600 Retina, MirrorOff, Online
Memory Module: LPDDR4, Hynix
AirPort: spairport_wireless_card_type_wifi (0x14E4, 0x4378), wl0: Aug 26 2023 17:55:53 version 18.20.439.0.7.8.163 FWID 01-f9b9247b
AirPort: 
Bluetooth: Version (null), 0 services, 0 devices, 0 incoming serial ports
Network Service: Wi-Fi, AirPort, en0
USB Device: USB31Bus
USB Device: USB31Bus
USB Device: USB3.0 Hub
USB Device: USB3.0 Card Reader
USB Device: USB 2.0 Hub
USB Device: USB 2.0 BILLBOARD
USB Device: USB2.0 Hub
USB Device: Deco LW
USB Device: USB 2.0 Hub
USB Device: Corsair Gaming SCIMITAR RGB Mouse
USB Device: PC-LM1E
Thunderbolt Bus: MacBook Pro, Apple Inc.
Thunderbolt Bus: MacBook Pro, Apple Inc.

