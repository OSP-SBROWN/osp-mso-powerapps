# MSO Power Apps Project - October 2025 Refresh

## Introduction 
This project contains the MSO (Macro Space Optimisation) Power Apps solution. MSO helps retail teams strike the optimal balance between categories across stores or clusters, ensuring macro space decisions align with performance goals. The October 2025 refresh focuses on modernizing existing workflows and implementing new features to improve organisational efficiency.

**Project Objectives:**
- Digitize macro space planning workflows
- Improve data visibility and reporting
- Enhance user experience across devices
- Integrate with existing Microsoft 365 ecosystem
- Ensure compliance with organizational standards

## Project Structure
```
MSO-October2025/
├── PowerApps/
│   └── MSO/
│       ├── MSO-PowerApp-Documentation.md    # Features, processes, SQL interactions
│       └── Readme.md
├── SQL/
│   └── MSO-DB-v6/                           # SQL Server project backing the app
├── README.md                                # This file
└── .git/                                   # Version control
```

## Getting Started

### Prerequisites
- Microsoft Power Platform environment access
- Power Apps license (per user or per app)
- Azure Active Directory account
- Power Platform CLI (for advanced development)

### Development Setup
1. **Access Power Apps Portal:** Navigate to [make.powerapps.com](https://make.powerapps.com)
2. **Select Environment:** Choose the appropriate development environment
3. **Import Solution:** Import the MSO solution package when available
4. **Configure Connections:** Set up data source connections
5. **Test Application:** Verify functionality in development environment

### Documentation
- **Complete Feature Documentation:** See `PowerApps/MSO/MSO-PowerApp-Documentation.md` for detailed features, processes, and SQL mappings
- **SQL Project Reference:** See `SQL/MSO-DB-v6` for database objects surfaced to the app
- **Business Requirements:** [Link to requirements document when available]
- **Technical Architecture:** Documented in the main documentation file

## Development and Deployment

### Environment Strategy
- **Development:** Feature development and initial testing
- **Test/Staging:** User acceptance testing and integration testing  
- **Production:** Live system for end users

### Solution Management
- Solutions are exported as managed packages for deployment
- Version control is maintained through Azure DevOps/Git
- Change management follows organizational approval processes

## Contribute
To contribute to this project:
1. Create a feature branch from main
2. Develop and test your changes in the development environment
3. Update documentation as needed
4. Submit a pull request for review
5. Deploy through the standard release pipeline 

If you want to learn more about creating good readme files then refer the following [guidelines](https://docs.microsoft.com/en-us/azure/devops/repos/git/create-a-readme?view=azure-devops). You can also seek inspiration from the below readme files:
- [ASP.NET Core](https://github.com/aspnet/Home)
- [Visual Studio Code](https://github.com/Microsoft/vscode)
- [Chakra Core](https://github.com/Microsoft/ChakraCore)