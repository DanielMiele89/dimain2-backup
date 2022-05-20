CREATE TABLE [dbo].[ClubAndRedeem] (
    [ID]         INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [ClubID]     INT NOT NULL,
    [RedeemID]   INT NOT NULL,
    [CategoryID] INT NOT NULL,
    [Priority]   INT NOT NULL,
    CONSTRAINT [PK_ClubAndRedeem] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [U_ClubAndRedeem] UNIQUE NONCLUSTERED ([ClubID] ASC, [RedeemID] ASC, [CategoryID] ASC)
);

