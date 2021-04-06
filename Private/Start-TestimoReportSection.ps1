function Start-TestimoReportSection {
    [cmdletBinding()]
    param(
        [string] $Name,
        [Array] $Data,
        [System.Collections.IDictionary]$Information,
        [Scriptblock]$SourceCode,
        [Array] $Results,
        [Array] $WarningsAndErrors,
        [switch] $HideSteps,
        [switch] $AlwaysShowSteps,
        [System.Collections.IDictionary]$TestResults,
        [string] $Type
    )
    [Array] $PassedTestsSingular = $Results | Where-Object { $_.Status -eq $true }
    [Array] $FailedTestsSingular = $Results | Where-Object { $_.Status -eq $false }
    [Array] $SkippedTestsSingular = $Results | Where-Object { $_.Status -ne $true -and $_.Status -ne $false }

    if ($Type -eq 'Forest') {
        $ResultsDisplay = $Results | Select-Object -Property DisplayName, Type, Category, Assesment, Importance, Action, Extended
    } elseif ($Type -eq 'DC') {
        $ResultsDisplay = $Results | Select-Object -Property DisplayName, Type, Category, Assesment, Importance, Action, Extended, Domain
    } elseif ($Type -eq 'Domain') {
        $ResultsDisplay = $Results | Select-Object -Property DisplayName, Type, Category, Assesment, Importance, Action, Extended, Domain, DomainController
    }


    $ColorPassed = 'LawnGreen'
    $ColorSkipped = 'DeepSkyBlue'
    $ColorFailed = 'TorchRed'
    $ColorPassedText = 'Black'
    $ColorFailedText = 'Black'
    $ColorSkippedText = 'Black'

    New-HTMLSection -HeaderText $Name -HeaderBackGroundColor CornflowerBlue -Direction column {
        New-HTMLSection -Invisible -Direction column {
            New-HTMLSection -HeaderText 'Information' {
                New-HTMLContainer {
                    New-HTMLChart {
                        New-ChartPie -Name 'Passed' -Value ($PassedTestsSingular.Count) -Color $ColorPassed
                        New-ChartPie -Name 'Failed' -Value ($FailedTestsSingular.Count) -Color $ColorFailed
                        New-ChartPie -Name 'Skipped' -Value ($SkippedTestsSingular.Count) -Color $ColorSkipped
                    } -Height 250
                    New-HTMLText -Text @(
                        "Below command was used to generate and asses current data that is visible in this report. "
                        "In case there are more information required feel free to confirm problems found yourself. "
                    ) -FontSize 10pt
                    New-HTMLCodeBlock -Code $SourceCode -Style 'PowerShell' -Theme enlighter
                    if ($WarningsAndErrors) {
                        New-HTMLSection -HeaderText 'Warnings & Errors' -HeaderBackGroundColor OrangePeel {
                            New-HTMLTable -DataTable $WarningsAndErrors -Filtering -PagingLength 7
                        }
                    }
                }
                New-HTMLContainer {
                    if ($Information.Source.Details) {
                        if ($Information.DataDescription) {
                            & $Information.DataDescription
                        } elseif ($Information.Source.Details.Description) {
                            New-HTMLText -Text $Information.Source.Details.Description -FontSize 10pt
                        }

                        $SummaryOfTests = foreach ($Test in $Information.Tests.Keys) {
                            if ($Information.Tests[$Test].Enable -eq $true -and $Information.Tests[$Test].Details.Description) {
                                New-HTMLListItem -FontSize 10pt -Text $Information.Tests[$Test].Name, " - ", $Information.Tests[$Test].Details.Description
                                if ($Information.Tests[$Test].Details.Resources) {
                                    New-HTMLList -FontSize 10pt {
                                        foreach ($Resource in $Information.Tests[$Test].Details.Resources) {
                                            if ($Resource.StartsWith('[')) {
                                                New-HTMLListItem -Text $Resource
                                            } else {
                                                # Since the link is given in pure form, we want to convert it to markdown link
                                                $Resource = "[$Resource]($Resource)"
                                                New-HTMLListItem -Text $Resource
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        if ($SummaryOfTests) {
                            New-HTMLList {
                                $SummaryOfTests
                            }
                        }

                        if ($Information.Source.Details.Resources) {
                            #New-HTMLText -LineBreak
                            New-HTMLText -Text 'Following resources may be helpful to understand this topic', ', please make sure to read those to understand this topic before following any instructions.' -FontSize 10pt -FontWeight bold, normal
                            New-HTMLList -FontSize 10pt {
                                foreach ($Resource in $Information.Source.Details.Resources) {
                                    if ($Resource.StartsWith('[')) {
                                        New-HTMLListItem -Text $Resource
                                    } else {
                                        # Since the link is given in pure form, we want to convert it to markdown link
                                        $Resource = "[$Resource]($Resource)"
                                        New-HTMLListItem -Text $Resource
                                    }
                                }
                            }
                        }
                    }
                    #New-HTMLText -FontSize 10pt -Text 'Summary of Test results for ', $Name -FontWeight bold
                    New-HTMLText -FontSize 10pt -Text @(
                        "In the table below you can find summary of tests executed in the "
                        $Name
                        " category. Each test has their "
                        "assesment level ", ', '
                        "importance level ", ' and '
                        "action ",
                        "defined. "
                        "Depending on the assesment, importance and action AD Team needs to investigate according to the steps provided including using their internal processes (for example SOP). "
                        "It's important to have an understanding what the test is trying to tell you and what solution is provided. "
                        "If you have doubts, or don't understand some test please consider talking to senior admins for guidance. "
                    ) -FontWeight normal, bold, normal, bold, normal, bold, normal, bold, normal, normal, normal, normal
                    New-HTMLTable -DataTable $ResultsDisplay {
                        & $TestResults['Configuration']['ResultConditions']
                    } -Filtering -PagingLength 10
                }
            }
        }
        # If there is no data to display we don't want to add empty table and section to the report. It makes no sense to take useful resources.
        if ($Data) {
            New-HTMLSection -HeaderText 'Data' {
                New-HTMLContainer {
                    if ($Information.DataInformation) {
                        & $Information.DataInformation
                    }
                    New-HTMLTable -DataTable $Data -Filtering {
                        if ($Information.DataHighlights) {
                            & $Information.DataHighlights
                        }
                    } -PagingLength 7 -DateTimeSortingFormat 'DD.MM.YYYY HH:mm:ss' -SearchBuilder
                }
            }
        }
        if ($Information.Solution) {
            if (($HideSteps.IsPresent -eq $false -and $FailedTestsSingular.Count -gt 0) -or $AlwaysShowSteps.IsPresent) {
                New-HTMLSection -Name 'Solution' {
                    & $Information.Solution
                }
            }
        }
    }
}