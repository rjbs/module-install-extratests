use inc::Module::Install;
name('Module-Install-ExtraTests');
all_from('lib/Module/Install/ExtraTests.pm');
extra_tests;
WriteAll;
