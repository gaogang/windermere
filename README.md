# Project Windermere

## What is Windermere 
Windermere is a collection of scripts aiming to bring Azure closer to DevOps engineers. 

## App

### Create a new app

```powershell
New-WeApp   -solutionName
            -runtime
            [ -size ]
            [ -repo ]
```
![Create an classic app](https://github.com/gaogang/windermere/blob/master/Docs/Images/we-classic-app.png)

This command Creates a classic web app in Azure with two deployment slots - development and production, and a repository in GitHub linked to the development slot.

#### Example

```powershell
New-WeApp -solutionName bronzefat999 -runtime '"node|10.15"' -size small
```

#### References
[Set up staging environments in Azure App Service](https://docs.microsoft.com/en-us/azure/app-service/deploy-staging-slots)
