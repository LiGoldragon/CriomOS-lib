{
  description = "CriomOS-lib — shared helpers and data files consumed by CriomOS and CriomOS-home.";

  outputs = { self, ... }: {
    lib = import ./lib { };
  };
}
