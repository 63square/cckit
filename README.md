# cckit

Rootkit for the Minecraft mod CC:Tweaked, this is very work-in-progress and targets version 1.115.1

### End Goals:
- Full end-user concealment
- Full Lua environment concealment
- Impossible removal during runtime
- Remote code execution
- Remote implant removal
- Remote device kill
- Hybrid modem + http networking

### Status

Currently the rootkit has partial end-user concealment and cannot be removed using standard methods.

It is currently possible to remove the implant by using Lua debug APIs to bypass the hooks and the end-user can detect the implant through error messages.