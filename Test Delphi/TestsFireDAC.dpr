program TestsFireDAC;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}
{$STRONGLINKTYPES ON}
uses
  FastMM4,
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ENDIF }
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  Tests.Driver.FireDAC in 'Tests.Driver.FireDAC.pas',
  Tests.Consts in 'Tests.Consts.pas',
  DBEngine.DriverFireDac in '..\Source\Drivers\DBEngine.DriverFireDac.pas',
  DBEngine.DriverFireDacTransaction in '..\Source\Drivers\DBEngine.DriverFireDacTransaction.pas',
  DBEngine.FactoryFireDac in '..\Source\Drivers\DBEngine.FactoryFireDac.pas',
  DBEngine.Consts in '..\Source\Core\DBEngine.Consts.pas',
  DBEngine.DriverConnection in '..\Source\Core\DBEngine.DriverConnection.pas',
  DBEngine.FactoryConnection in '..\Source\Core\DBEngine.FactoryConnection.pas',
  DBEngine.FactoryInterfaces in '..\Source\Core\DBEngine.FactoryInterfaces.pas',
  DBEngine.GuardConnection in '..\Source\Core\DBEngine.GuardConnection.pas',
  DBEngine.PoolConnection in '..\Source\Core\DBEngine.PoolConnection.pas';

{$IFNDEF TESTINSIGHT}
var
  runner: ITestRunner;
  results: IRunResults;
  logger: ITestLogger;
  nunitLogger : ITestLogger;
{$ENDIF}
begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
{$ELSE}
  try
    //Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    //Create the test runner
    runner := TDUnitX.CreateRunner;
    //Tell the runner to use RTTI to find Fixtures
    runner.UseRTTI := True;
    //When true, Assertions must be made during tests;
    runner.FailsOnNoAsserts := False;

    //tell the runner how we will log things
    //Log to the console window if desired
    if TDUnitX.Options.ConsoleMode <> TDunitXConsoleMode.Off then
    begin
      logger := TDUnitXConsoleLogger.Create(TDUnitX.Options.ConsoleMode = TDunitXConsoleMode.Quiet);
      runner.AddLogger(logger);
    end;
    //Generate an NUnit compatible XML File
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);

    //Run tests
    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    //We don't want this happening when running under CI.
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
{$ENDIF}
end.

