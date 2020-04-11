# Project Windermere

## What is Windermere 
Windermere is a collection of scripts aiming to bring Azure closer to DevOps engineers. 

## Getting Started

### Prerequisites

1. PowershellForGithub

``` powershell
Install-Module -Name PowerShellForGitHub
```

### Examples 
### Create a new React App

```powershell
New-WeApp -solutionName bronzefat999 -runtime 'node|10.15' -build react -size small
```

![Create an classic app](https://github.com/gaogang/windermere/blob/master/Docs/Images/we-classic-app.png)

#### behind the scene 

The script creates:
 1. A skeleton react app 
 2. A Github repository
 3. An App Service Plan
 4. An Azure App Service with two deployment slots - **development** and **production** and
 5. a continuous integration from the Github repository to the **development** deployment slot

 #### References
 ![Set up staging environments in Azure App Service](https://docs.microsoft.com/en-us/azure/app-service/deploy-staging-slots)


