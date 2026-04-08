{
  stdenv,
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  cctools,
  remarshal,
  ttfautohint-nox,
  # Custom font set options
  privateBuildPlan ? null,
  extraParameters ? null,
  set ? null,
}:

buildNpmPackage rec {
  pname = "Iosevka${toString set}";
  version = "34.2.1";

  src = fetchFromGitHub {
    owner = "be5invis";
    repo = "iosevka";
    rev = "v${version}";
    hash = "sha256-yj46lNYOzaopu5Mo68jwh+xf/q/bjMmQdprh6e56eeY=";
  };

  npmDepsHash = "sha256-it0YwPcoYCIMddktgywBuYvvx3Psghoii3pu0K3RDlI=";

  nativeBuildInputs = [
    remarshal
    ttfautohint-nox
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    cctools
  ];

  buildPlan =
    if builtins.isAttrs privateBuildPlan then
      builtins.toJSON { buildPlans.${pname} = privateBuildPlan; }
    else
      privateBuildPlan;

  inherit extraParameters;
  passAsFile = [
    "extraParameters"
  ]
  ++ lib.optionals (
    !(builtins.isString privateBuildPlan && lib.hasPrefix builtins.storeDir privateBuildPlan)
  ) [ "buildPlan" ];

  configurePhase = ''
    runHook preConfigure
    ${lib.optionalString (builtins.isAttrs privateBuildPlan) ''
      remarshal -i "$buildPlanPath" -o private-build-plans.toml -if json -of toml
    ''}
    ${lib.optionalString
      (builtins.isString privateBuildPlan && (!lib.hasPrefix builtins.storeDir privateBuildPlan))
      ''
        cp "$buildPlanPath" private-build-plans.toml
      ''
    }
    ${lib.optionalString
      (builtins.isString privateBuildPlan && (lib.hasPrefix builtins.storeDir privateBuildPlan))
      ''
        cp "$buildPlan" private-build-plans.toml
      ''
    }
    ${lib.optionalString (extraParameters != null) ''
      echo -e "\n" >> params/parameters.toml
      cat "$extraParametersPath" >> params/parameters.toml
    ''}
    runHook postConfigure
  '';

  buildPhase = ''
    export HOME=$TMPDIR
    runHook preBuild

    npm run build --no-update-notifier --targets ttf::"$pname" -- --jCmd=$NIX_BUILD_CORES --verbosity=9 | cat

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    fontdir="$out/share/fonts/truetype"
    install -d "$fontdir"
    install "dist/$pname/TTF"/* "$fontdir"
    runHook postInstall
  '';

  enableParallelBuilding = true;
  requiredSystemFeatures = [ "big-parallel" ];

  meta = {
    homepage = "https://typeof.net/Iosevka/";
    description = "Versatile typeface for code, from code";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
}
