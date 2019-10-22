    #     ___  ____     _    ____ _     _____
    #    / _ \|  _ \   / \  / ___| |   | ____|
    #   | | | | |_) | / _ \| |   | |   |  _|
    #   | |_| |  _ < / ___ | |___| |___| |___
    #    \___/|_| \_/_/   \_\____|_____|_____|
***
This example creates an OCI instance and attach a second vNIC to the instnace.
Then download the config script to add ip address to the 2dn vNIC. 

## Files in the configuration

#### `env-vars`
Is used to export the environmental variables used in the configuration. These are usually authentication related, be sure to exclude this file from your version control system. It's typical to keep this file outside of the configuration.

Before you plan, apply, or destroy the configuration source the file -  
`$ . env-vars`

#### `user_data.tpl`
Enabling and configuring firewall to do forwarding.

#### `instance.tf`
Defines the instance resources.

#### variables.tf
Defines resources.

#### provider.tf
Defines provider resources.

#### output.tf
Displays the output.
