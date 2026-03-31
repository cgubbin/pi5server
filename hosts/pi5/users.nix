{...}: {
  users.users.kit = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL7rSy84QXoI18bEev+08FkaPH8DkdlXAUq6iQCOsiMq chris.gubbin@googlemail.com"
    ];
  };
}
