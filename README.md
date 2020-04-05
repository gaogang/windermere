# Project Windermere

## What is Windermere 
Windermere is a collection of scripts aiming to bring Azure closer to DevOps engineers. 

## Use cases

### Create a new app

![Create an classic app](https://github.com/gaogang/windermere/Docs/Images/we-classic-app.png)

```powershell
New-WeApp   -solutionName
            -runtime
            [ -size ]
            [ -repo ]
```

#### Example

```powershell
New-WeApp -solutionName bronzefat999 -runtime '"node|10.15"' -size small
```

The code above creates a web app with two deployment slots - development and production, and a repository in GitHub linked to the development slot.

