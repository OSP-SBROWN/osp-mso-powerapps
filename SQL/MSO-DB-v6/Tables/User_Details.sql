CREATE TABLE [ui].[User_Details] (
    [User_ID]           INT            IDENTITY (1, 1) NOT NULL,
    [User_DisplayName]  VARCHAR (255)  NULL,
    [User_ContactEmail] VARCHAR (255)  NULL,
    [User_IsOSP]        BIT            NULL,
    [User_Status]       VARCHAR (24)   NULL,
    [User_Functional]   BIT            NULL,
    [User_Admin]        BIT            NULL,
    [User_Blocked]      BIT            NULL,
    [User_LoginEmail]   NVARCHAR (MAX) NULL,
    [User_MFAMobile]    VARCHAR (24)   NULL,
    [User_ThemeID]      INT            NOT NULL,
    [User_HierMan]      BIT            NULL
);


GO

