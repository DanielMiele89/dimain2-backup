CREATE TABLE [Relational].[__NominatedOfferMember_TableNames_Archived] (
    [TableID]   INT           IDENTITY (1, 1) NOT NULL,
    [TableName] VARCHAR (200) NULL,
    CONSTRAINT [pk_TableID] PRIMARY KEY CLUSTERED ([TableID] ASC)
);




GO
GRANT ALTER
    ON OBJECT::[Relational].[__NominatedOfferMember_TableNames_Archived] TO [DataTeam]
    AS [dbo];


GO
GRANT ALTER
    ON OBJECT::[Relational].[__NominatedOfferMember_TableNames_Archived] TO [CampaignExecutionUser]
    AS [dbo];

