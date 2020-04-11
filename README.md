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

Create a react app in Azure App Service with two deployment slots - development and production, and a repository in GitHub linked to the development slot.
