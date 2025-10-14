CREATE TABLE [dbo].[NavContent] (
    [ItemKey]         INT           NOT NULL,
    [ItemDisplayName] VARCHAR (255) NOT NULL,
    [ItemIconName]    VARCHAR (255) NULL,
    [ItemIconColor]   VARCHAR (50)  NULL,
    [ItemExpanded]    BIT           NULL,
    [ItemVisible]     BIT           NULL,
    [ItemParentKey]   INT           NULL
);
GO

