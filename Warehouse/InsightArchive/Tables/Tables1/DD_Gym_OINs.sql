CREATE TABLE [InsightArchive].[DD_Gym_OINs] (
    [OIN]             INT          NOT NULL,
    [GymID]           INT          NOT NULL,
    [GymName]         VARCHAR (50) NOT NULL,
    [Match_Narrative] VARCHAR (50) NOT NULL,
    [StartDate]       DATE         NOT NULL,
    [EndDate]         DATE         NULL,
    PRIMARY KEY CLUSTERED ([OIN] ASC)
);

