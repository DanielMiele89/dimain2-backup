CREATE TABLE [Relational].[BrandMID] (
    [BrandMIDID]     INT          IDENTITY (1, 1) NOT NULL,
    [BrandID]        SMALLINT     NOT NULL,
    [MID]            VARCHAR (22) NULL,
    [Country]        VARCHAR (3)  NULL,
    [Narrative]      VARCHAR (50) NOT NULL,
    [IsHighVariance] BIT          NOT NULL,
    CONSTRAINT [PK_BrandMID] PRIMARY KEY CLUSTERED ([BrandMIDID] ASC),
    CONSTRAINT [FK_BrandMID_Brand] FOREIGN KEY ([BrandID]) REFERENCES [Relational].[Brand_Old] ([BrandID])
);


GO
CREATE NONCLUSTERED INDEX [IX_BrandMID_BrandID]
    ON [Relational].[BrandMID]([BrandID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_BrandMID_MID]
    ON [Relational].[BrandMID]([MID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_BrandMID_Country]
    ON [Relational].[BrandMID]([Country] ASC);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff1]
    ON [Relational].[BrandMID]([IsHighVariance] ASC, [Country] ASC, [MID] ASC)
    INCLUDE([Narrative]);

