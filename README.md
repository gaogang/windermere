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

### Create a new app

#### Create a react app

```powershell
New-WeApp -solutionName bronzefat999 -runtime 'node|10.15' -build react -size small
```

#### Create a express app

```powershell
New-WeApp -solutionName bronzefat999 -runtime 'node|10.15' -build express -size small
```

#### behind the scene 

![Create an classic app](https://github.com/gaogang/windermere/blob/master/Docs/Images/we-classic-app.png)

The script creates:
 1. A skeleton app (react, express, etc) 
 2. A Github repository
 3. An App Service Plan
 4. An Azure App Service with two deployment slots - **development** and **production** and
 5. a continuous integration from the Github repository to the **development** deployment slot

 #### References
 ![Set up staging environments in Azure App Service](https://docs.microsoft.com/en-us/azure/app-service/deploy-staging-slots)


