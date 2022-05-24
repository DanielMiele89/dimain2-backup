CREATE TABLE [Relational].[PostStatus] (
    [PostStatusID]   TINYINT  IDENTITY (1, 1) NOT NULL,
    [PostStatusDesc] CHAR (1) NOT NULL,
    CONSTRAINT [PK_Relational_PostStatus] PRIMARY KEY CLUSTERED ([PostStatusID] ASC)
);

