# Glossary

Architect's Build Lab, Episode 3. The words used in the video, in the order they come up. One or two lines each, in plain language.

| Word | What it means here |
|---|---|
| Power Platform | Microsoft's low code family. In this build we use Power Apps for the screen and Power Automate for the flow. |
| Dataverse | The database behind Power Platform. It also runs our server side code. |
| Plug-in | A small piece of C# code that Dataverse runs for us on the server. Ours makes the call to Databricks. |
| Custom API | A named action in Dataverse. The app and the flow call the action, and the action runs the plug-in. |
| Virtual network (VNet) | Your own private network inside Azure. Nothing gets in or out unless you allow it. |
| Subnet | A slice of the VNet's address range, kept for one purpose, such as the cluster or the private endpoints. |
| Subnet delegation | Handing one subnet to one Azure service. We delegate a subnet to Power Platform so its plug-ins can run inside it. |
| Virtual network support | The Power Platform feature that runs plug-in calls inside your delegated subnet. People also call it VNet injection. |
| Private Link and private endpoint | A private endpoint is a network card inside your subnet that stands for a service. Traffic to the workspace goes to that private address and never crosses the public internet. |
| Private DNS zone | The phone book for the private road. It makes the workspace name answer with the private address when asked from inside the VNet. |
| NAT gateway | A one way exit for the cluster machines. They can reach out for updates, nobody can reach in, and they have no public IP. |
| VNet peering | A private join between two VNets. Power Platform needs a subnet in two paired regions, so we peer the second VNet to the first. |
| Managed identity | An identity that Azure looks after. There is no password or secret to store or rotate. |
| Federated credential | The trust rule on the managed identity. It says this exact plug-in, in this exact environment, may ask for a token as this identity. |
| Enterprise policy | The Azure resource that tells Power Platform which subnets to use. You create it, then link it to the environment. |
| Public network access | The workspace setting for the public door. We switch it off at the end, so the open internet gets a 403. |
| Service principal | How the managed identity appears inside Databricks. We add it to the workspace and give it only the rights it needs. |
| Plug-in trace log | The Dataverse log where the plug-in writes its steps. We turn it on in the admin center and read it as proof. |
