CREATE TABLE [Derived].[NameGenderDictionary] (
    [ID]             INT          IDENTITY (1, 1) NOT NULL,
    [FirstName]      VARCHAR (50) NULL,
    [InferredGender] VARCHAR (10) NULL,
    [StartDate]      DATE         NULL,
    [EndDate]        DATE         NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

