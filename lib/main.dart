// import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:leasure_nft/app/core/assets/app_images.dart';
import 'package:leasure_nft/app/routes/app_pages.dart';
import 'package:leasure_nft/app/routes/app_routes.dart';
import 'package:leasure_nft/app/services/initial_setting_services.dart';
import 'package:leasure_nft/firebase_options.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

Future<void> _initServices() async {
  Get.log("Initial Servicess Starting ..... ");
  await GetStorage.init();
  WidgetsFlutterBinding.ensureInitialized();

  // Clear cache on startup
  await _clearCacheOnStartup();

  // WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Get.putAsync(() => InitialSettingServices().init());
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("firebase error = ${e.toString()}");
  }

  Get.log("Initial Servicess Started!");
}

Future<void> _clearCacheOnStartup() async {
  try {
    if (kIsWeb) {
      // Clear web cache
      if (html.window.localStorage.isNotEmpty) {
        // Keep only essential data, clear rest
        final deviceId = html.window.localStorage['deviceId'];
        html.window.localStorage.clear();
        if (deviceId != null) {
          html.window.localStorage['deviceId'] = deviceId;
        }
      }

      // Clear session storage
      html.window.sessionStorage.clear();

      Get.log("✅ Web cache cleared on startup");
    }

    // Task-related cache clearing disabled - preserve task data
    // Only clear non-task related cache if needed

    Get.log("✅ App cache cleared on startup");
  } catch (e) {
    Get.log("❌ Error clearing cache: $e");
  }
}

void main() async {
  await _initServices();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Offset buttonPosition = Offset(0, 0); // Initial position of button
  @override
  void initState() {
    super.initState();
    // Set initial position to bottom-right corner
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        buttonPosition = Offset(
          MediaQuery.of(context).size.width - 80, // Adjust X to be right
          MediaQuery.of(context).size.height - 90, // Adjust Y to be bottom
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.height),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: GetMaterialApp(
          debugShowCheckedModeBanner: false,
          defaultTransition: Transition.leftToRight,
          title: 'Leasure NFT',
          themeMode: ThemeMode.system,
          getPages: AppPages.pages,
          builder: (context, child) {
            return Stack(
              children: [
                child!,
                Positioned(
                  left: buttonPosition.dx,
                  top: buttonPosition.dy,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        buttonPosition += details.delta;
                      });
                    },
                    onTap: () {},
                    child: FloatingActionButton(
                      backgroundColor: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Image(
                          image: AssetImage(AppImages.whatsappLogo),
                          fit: BoxFit.contain,
                        ),
                      ),
                      onPressed: () async {
                        if (await canLaunchUrl(Uri.parse(
                            "https://whatsapp.com/channel/0029VbAUg4UE50UaeIm4xz0w"))) {
                          await launchUrl(
                              Uri.parse(
                                  "https://whatsapp.com/channel/0029VbAUg4UE50UaeIm4xz0w"),
                              mode: LaunchMode.externalApplication);
                        } else {
                          Get.log(
                              "❌ Could not launch https://whatsapp.com/channel/0029VbAUg4UE50UaeIm4xz0w}");
                        }
                      },
                    ),
                  ),
                ),
              ],
            );
          },
          initialRoute: AppRoutes.initial,
          theme: Get.find<InitialSettingServices>().getLightTheme(),
        ),
      ),
    );
  }
}

// "hosting": {
//     "public": "build/web",
//     "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
//     "rewrites": [
//       {
//         "source": "**",
//         "destination": "/index.html"
//       }
//     ],
//     "errorPages": {
//       "404": "/404.html"
//     }
//   }
