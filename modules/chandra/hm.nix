{...}: {
  environment.extraInit = builtins.readFile ./hm.sh;
}
