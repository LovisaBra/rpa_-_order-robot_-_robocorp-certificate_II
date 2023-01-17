*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem
Library             RPA.Dialogs
Library             RPA.Robocloud.Secrets


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Get orders
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}    ${row}[Order number]
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close Browser


*** Keywords ***
Open the robot order website
    ${url}=    Get Secret    website
    Open Available Browser    ${url}[url]

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True
    RETURN    ${orders}

Close the annoying modal
    Wait Until Element Is Visible    css:div.modal-content
    Click Button    OK

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    Preview

Submit the order
    FOR    ${i}    IN RANGE    100
        Click Element When Visible    id:order
        Sleep    2s
        ${check}=    Is Element Visible    id:receipt
        IF    ${check}            BREAK
    END

Store the receipt as a PDF file
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}${row}.pdf

Take a screenshot of the robot
    [Arguments]    ${row}
    Screenshot    robot-preview-image    ${OUTPUT_DIR}${/}${row}.PNG

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}    ${row}
    Open Pdf    ${OUTPUT_DIR}${/}${row}.pdf
    ${image_files}=    Create List
    ...    ${OUTPUT_DIR}${/}${row}.PNG:align=center
    Add Files To PDF    ${image_files}    ${OUTPUT_DIR}${/}${row}.pdf    append=True
    #Close Pdf    ${OUTPUT_DIR}${/}${row}.pdf

Go to order another robot
    Click Button    order-another

Create a ZIP file of the receipts
    Add heading    Name zip file
    Add text input    FileName    label=Name
    ${result}=    Run dialog
    Archive Folder With Zip    ${OUTPUT_DIR}${/}    ${result.FileName}.zip

Close Browser
    Close Browser
