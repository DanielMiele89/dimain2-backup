CREATE TABLE [Relational].[Location] (
    [LocationID]            INT          IDENTITY (1, 1) NOT NULL,
    [ConsumerCombinationID] INT          NOT NULL,
    [LocationAddress]       VARCHAR (50) NOT NULL,
    [IsNonLocational]       BIT          NOT NULL,
    CONSTRAINT [PK_Relational_Location] PRIMARY KEY CLUSTERED ([LocationID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Relational_Location_Cover]
    ON [Relational].[Location]([IsNonLocational] ASC, [ConsumerCombinationID] ASC, [LocationAddress] ASC) WITH (FILLFACTOR = 80);

