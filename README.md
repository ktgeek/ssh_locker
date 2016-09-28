This small deamon listens for your OS X screen to be locked and then
stops your ssh-agent if its running.

Previous versions of this used to also lock a named keychain. Because
Apple has removed ssh/Keychain integratin in Sierra, the keychain
integration has been removed from ssh_locker.  The downside of this
change is there's no nice OS level gui to enter your ssh passphrase
and add the key to the ssh-agent.

To get close to similar functionality, add "AddKeysToAgent yes" to
your ssh config.
