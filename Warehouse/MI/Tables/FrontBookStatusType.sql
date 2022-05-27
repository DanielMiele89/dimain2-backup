CREATE TABLE [MI].[FrontBookStatusType] (
    [ID]                     TINYINT       IDENTITY (1, 1) NOT NULL,
    [SchemeMembershipTypeID] TINYINT       NOT NULL,
    [PrevSchemeID]           TINYINT       NOT NULL,
    [ChangeType]             VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_MI_FrontBookStatusType] PRIMARY KEY CLUSTERED ([ID] ASC)
);

