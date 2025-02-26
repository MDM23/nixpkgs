{
  lib,
  python3,
  fetchPypi,
  groff,
  less,
  nix-update-script,
  testers,
  awscli,
}:

let
  self = python3.pkgs.buildPythonApplication rec {
    pname = "awscli";
    # N.B: if you change this, change botocore and boto3 to a matching version too
    # check e.g. https://github.com/aws/aws-cli/blob/1.33.21/setup.py
    version = "1.36.40";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-4qiPiNwW1cDyY3mv1vJUCX5T6LNMghZOWfQWXbbubfo=";
    };

    pythonRelaxDeps = [
      # botocore must not be relaxed
      "colorama"
      "docutils"
      "rsa"
    ];

    build-system = [
      python3.pkgs.setuptools
    ];

    dependencies = with python3.pkgs; [
      botocore
      s3transfer
      colorama
      docutils
      rsa
      pyyaml
      groff
      less
    ];

    postInstall = ''
      mkdir -p $out/share/bash-completion/completions
      echo "complete -C $out/bin/aws_completer aws" > $out/share/bash-completion/completions/awscli

      mkdir -p $out/share/zsh/site-functions
      mv $out/bin/aws_zsh_completer.sh $out/share/zsh/site-functions

      rm $out/bin/aws.cmd
    '';

    doInstallCheck = true;

    installCheckPhase = ''
      runHook preInstallCheck

      $out/bin/aws --version | grep "${python3.pkgs.botocore.version}"
      $out/bin/aws --version | grep "${version}"

      runHook postInstallCheck
    '';

    passthru = {
      python = python3; # for aws_shell
      updateScript = nix-update-script {
        extraArgs = [ "--version=skip" ];
      };
      tests.version = testers.testVersion {
        package = awscli;
        command = "aws --version";
        inherit version;
      };
    };

    meta = {
      homepage = "https://aws.amazon.com/cli/";
      changelog = "https://github.com/aws/aws-cli/blob/${version}/CHANGELOG.rst";
      description = "Unified tool to manage your AWS services";
      license = lib.licenses.asl20;
      mainProgram = "aws";
      maintainers = with lib.maintainers; [ anthonyroussel ];
    };
  };
in
assert self ? pythonRelaxDeps -> !(lib.elem "botocore" self.pythonRelaxDeps);
self
