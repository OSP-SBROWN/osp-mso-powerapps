CREATE TABLE [dbo].[Users] (
    [MyID]                 NVARCHAR (4)   NOT NULL,
    [DisplayName]          VARCHAR (255)  NULL,
    [Email]                VARCHAR (255)  NULL,
    [IsOSPAdmin]           BIT            NULL,
    [Status]               VARCHAR (24)   NULL,
    [FunctionalUser]       INT            NULL,
    [AdminUser]            INT            NULL,
    [BlockAccess]          INT            NULL,
    [O365Email]            NVARCHAR (MAX) NULL,
    [MFA_Mobile]           VARCHAR (24)   NULL,
    [ColourMode]           CHAR (1)       NOT NULL,
    [HierarchyMaintenance] BIT            NULL
);


GO

