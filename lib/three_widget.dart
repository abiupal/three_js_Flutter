import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/texture.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three_dart.dart' as THREE;
import 'controller_dat_gui.dart';

class ThreeWidget extends StatefulWidget {
  const ThreeWidget({Key? key}) : super(key: key);

  @override
  State<ThreeWidget> createState() => _MyThreeWidgetState();
}

class _MyThreeWidgetState extends State<ThreeWidget>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late FlutterGlPlugin three3dRender;
  THREE.WebGLRenderer? renderer;

  late double width;
  late double height;
  Size? screenSize;

  late THREE.Scene scene;
  late THREE.Camera camera;
  late THREE.Mesh mesh;
  late THREE.Group group;
  late THREE.Texture texture;
  late THREE.AxesHelper axes;
  late THREE.SpotLight spotLight;

  late THREE.CameraHelper cameraHelper;
  late THREE.SpotLightHelper spotLightHelper;

  double dpr = 1.0;

  bool readyRender = false; //Renderer の使用判定
  bool verbose = true;
  bool disposed = false;

  late THREE.WebGLRenderTarget renderTarget;
  dynamic sourceTexture;

  late Timer timer; //初回美容画までの確認
  late AnimationController anime;
  final Duration animeDuration = Duration(milliseconds: 100);
  int numberOfObjects = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    anime = AnimationController(
      vsync: this, // the SingleTickerProviderStateMixin
      duration: animeDuration,
    );
  }

  @override
  void dispose() {
    disposed = true;
    three3dRender.dispose();

    anime.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // @override
  // void didUpdateWidget(ThreeWidget oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   renderScene();
  //   anime.duration = animeDuration;
  // }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    three3dRender = FlutterGlPlugin();

    Map<String, dynamic> options = {
      "antialias": true,
      "alpha": false,
      "width": width.toInt(),
      "height": height.toInt(),
      "dpr": dpr
    };

    await three3dRender.initialize(options: options);

    setState(() {});

    // Wait for web
    Future.delayed(const Duration(milliseconds: 500), () async {
      await three3dRender.prepareContext();

      initScene();
    });
  }

  initSize(BuildContext context) {
    if (screenSize != null) {
      return;
    }
    //ウィンドウサイズの確認
    onWindowResize();

    initPlatformState();
  }

  @override
  void didChangeMetrics() {
    setState(() {
      onWindowResize();
    });
  }

  //ウィンドウサイズの変更
  void onWindowResize() {
    final mqd = MediaQuery.of(context);
    screenSize = mqd.size;
    dpr = mqd.devicePixelRatio;
    //print('screenSize: ${screenSize!.width}, ${screenSize!.height}');
    width = screenSize!.width * 4 / 5;
    height = screenSize!.height * 4 / 5;
    if (readyRender) {
      camera.aspect = width / height;
      camera.updateProjectionMatrix();
      renderer!.setSize(width, height, true);
      //print('onWindowResize: $width, $height');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (BuildContext context) {
      initSize(context);
      return SingleChildScrollView(child: _build(context));
    });
  }

  Widget _build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Builder(builder: (BuildContext context) {
        if (kIsWeb) {
          return Stack(
            children: <Widget>[
              three3dRender.isInitialized
                  ? HtmlElementView(
                      viewType: three3dRender.textureId!.toString(),
                    )
                  : Container(),
              Align(alignment: Alignment.topRight, child: DatGuiWidget()),
            ],
          );
        } else {
          return Stack(
            children: <Widget>[
              three3dRender.isInitialized
                  ? Texture(textureId: three3dRender.textureId!)
                  : Container(),
              Align(alignment: Alignment.topRight, child: DatGuiWidget())
            ],
          );
        }
      }),
    );
  }

  void render() {
    if (disposed) return;

    //int t0 = DateTime.now().millisecondsSinceEpoch;

    final gl = three3dRender.gl;
    renderer!.render(scene, camera);

    //int t1 = DateTime.now().millisecondsSinceEpoch;

    if (verbose) {
      // Debug
    }
    gl.flush();

    if (!kIsWeb) {
      three3dRender.updateTexture(sourceTexture);
    }
  }

  void initRenderer() {
    scene = THREE.Scene();
    camera = THREE.PerspectiveCamera(45, width / height, 0.1, 1000);

    Map<String, dynamic> options = {
      "width": width,
      "height": height,
      "gl": three3dRender.gl,
      "antialias": true,
      "canvas": three3dRender.element,
    };
    renderer = THREE.WebGLRenderer(options);
    renderer!.setClearColor(THREE.Color(0xeeeeee));
    renderer!.setPixelRatio(dpr);

    //print('initRenderer: $width, $height');
    renderer!.setSize(width, height, false);
    renderer!.shadowMap.enabled = true;

    if (!kIsWeb) {
      var pars = THREE.WebGLRenderTargetOptions({
        "minFilter": THREE.LinearFilter,
        "magFilter": THREE.LinearFilter,
        "format": THREE.RGBAFormat
      });
      renderTarget = THREE.WebGLMultisampleRenderTarget(
          (width * dpr).toInt(), (height * dpr).toInt(), pars);
      renderer!.setRenderTarget(renderTarget);
      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget);
    }
    readyRender = true;
  }

  void initPage() {
    axes = THREE.AxesHelper(20);
    scene.add(axes);

    var planeGeometry = THREE.PlaneGeometry(60, 20);
    var planeMaterial = THREE.MeshLambertMaterial({
      "color": THREE.Color(0xcccccc),
    });
    var plane = THREE.Mesh(planeGeometry, planeMaterial);
    plane.rotation.x = -0.5 * pi;
    plane.position.x = 15;
    plane.position.y = 0;
    plane.position.z = 0;
    plane.receiveShadow = true;
    plane.name = 'plane';
    scene.add(plane);

    var cubeGeometry = THREE.BoxGeometry(4, 4, 4);
    var cubeMaterial = THREE.MeshLambertMaterial({
      "color": THREE.Color(0xff0000),
      "wireframe": false,
    });
    var cube = THREE.Mesh(cubeGeometry, cubeMaterial);
    cube.position.x = -4;
    cube.position.y = 3;
    cube.position.z = 0;
    cube.castShadow = true;
    cube.name = 'rotationSpeed';
    DatGuiController.to.add(cube.name, 0.02, 0.0, 0.5);
    scene.add(cube);

    var sphereGeometry = THREE.SphereGeometry(4, 20, 20);
    var sphereMaterial = THREE.MeshLambertMaterial({
      "color": THREE.Color(0x7777ff),
      "wireframe": false,
    });
    var sphere = THREE.Mesh(sphereGeometry, sphereMaterial);
    sphere.position.x = 20;
    sphere.position.y = 4;
    sphere.position.z = 2;
    sphere.castShadow = true;
    sphere.name = 'bouncingSpeed';
    DatGuiController.to.add(sphere.name, 0.03, 0.0, 0.5);
    scene.add(sphere);

    camera.position.x = -30;
    camera.position.y = 40;
    camera.position.z = 30;
    camera.lookAt(scene.position);

    spotLight = THREE.SpotLight(THREE.Color(0xffffff));
    spotLight.position.set(-20, 30, -5);
    spotLight.castShadow = true;
    scene.add(spotLight);

    cameraHelper = THREE.CameraHelper(camera);
    spotLightHelper = THREE.SpotLightHelper(spotLight, THREE.Color(0xff0000));
    //scene.add(cameraHelper);
    scene.add(spotLightHelper);

    numberOfObjects = scene.children.length;
    render();
  }

  void initScene() {
    initRenderer();
    initPage();
    _startTimer();
  }

  void _startTimer() {
    const duration = Duration(milliseconds: 50);
    timer = Timer.periodic(duration, (Timer timer) {
      setState(() {
        if (three3dRender.isInitialized) {
          renderScene();
          //timer.cancel();
        }
      });
    });
  }

  (THREE.Object3D? found, double? value) _getValueObject(final String name) {
    var allChildren = scene.children;
    THREE.Object3D? foundObject = allChildren.firstWhere(
      (object) => object.name == name,
      orElse: () => null as THREE.Object3D,
    );
    double? value = DatGuiController.to.getValue(name);

    return (foundObject, value);
  }

  void renderScene() {
    String name = 'rotationSpeed';
    final (cube, value1) = _getValueObject(name);
    if (null == cube) return;
    if (null == value1) return;
    cube.rotation.x += value1;
    cube.rotation.y += value1;
    cube.rotation.z += value1;

    name = 'bouncingSpeed';
    final (sphere, value2) = _getValueObject(name);
    if (null == sphere) return;
    if (null == value2) return;
    double step = DatGuiController.to.step;
    step += value2;
    sphere.position.x = 20.0 + (10.0 * (cos(step)));
    sphere.position.y = 2.0 + (10.0 * sin(step).abs());
    DatGuiController.to.step = step;

    render();
  }
}
