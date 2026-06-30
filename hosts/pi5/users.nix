{...}: {
  users.users.kit = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    hashedPassword = "$y$j9T$ry6ffk.Kmkb9HSkyn9j3v0$5Rd1rGJb15lvcuA9m5Wnqt6AIFW9wQDXv6QJXfH33B1";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL7rSy84QXoI18bEev+08FkaPH8DkdlXAUq6iQCOsiMq chris.gubbin@googlemail.com"
    ];
  };
}
