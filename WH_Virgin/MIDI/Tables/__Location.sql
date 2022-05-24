CREATE TABLE [MIDI].[__Location] (
    [LocationID]            INT          IDENTITY (1, 1) NOT NULL,
    [ConsumerCombinationID] INT          NOT NULL,
    [LocationAddress]       VARCHAR (50) NOT NULL,
    [IsNonLocational]       BIT          NOT NULL,
    CONSTRAINT [PK_Relational_Location] PRIMARY KEY CLUSTERED ([LocationID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff]
    ON [MIDI].[__Location]([ConsumerCombinationID] ASC, [LocationAddress] ASC, [IsNonLocational] ASC)
    INCLUDE([LocationID]);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff2]
    ON [MIDI].[__Location]([IsNonLocational] ASC, [ConsumerCombinationID] ASC, [LocationAddress] ASC)
    INCLUDE([LocationID]);

