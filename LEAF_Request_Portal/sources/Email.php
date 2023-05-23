<?php
/*
 * As a work of the United States government, this project is in the public domain within the United States.
 */

/*
    Emailer
    Date Created: September 19, 2008

*/

namespace Portal;

class Email
{
    public string $emailSender = '';

    public string $emailBody = '';

    private string $emailFrom = 'LEAF@localhost';

    private string $emailRecipient = '';

    private string $emailSubject = '';

    private string $siteRoot = "";

    private array $emailCC = array();

    private array $emailBCC = array();

    public array $smartyVariables = array();

    private object $position;

    private object $employee;

    private object $group;

    private object $portal_db;

    private object $nexus_db;

    private bool $orgchartInitialized = false;

    private int $recordID;

    const SEND_BACK = -1;
    const NOTIFY_NEXT = -2;
    const NOTIFY_COMPLETE = -3;
    const EMAIL_REMINDER = -4;
    const AUTOMATED_EMAIL_REMINDER = -5;

    public function __construct()
    {
        $this->initPortalDB();
        $this->initNexusDB();

        if(!empty($_SERVER['REQUEST_URI'])){
            $this->siteRoot = "https://" . HTTP_HOST . dirname($_SERVER['REQUEST_URI']) . '/';
        }
        else{
            $this->siteRoot = "https://" . HTTP_HOST . '/';
        }

        $apiEntry = strpos($this->siteRoot, '/api/');
        if ($apiEntry !== false) {
            $this->siteRoot = substr($this->siteRoot, 0, $apiEntry + 1);
        }
    }

    /**
     * @return string
     *
     * Created at: 5/10/2023, 11:11:05 AM (America/New_York)
     */
    public function getRecipients(): string
    {
        return $this->emailRecipient;
    }

    /**
     * @return string
     *
     * Created at: 5/10/2023, 11:11:32 AM (America/New_York)
     */
    public function getSubject(): string
    {
        return $this->emailSubject;
    }

    /**
     * This allows us to set the site root outside of the email class, since this could be called from command line instead of through a browser request.
     * @param string $siteRoot
     */
    public function setSiteRoot(string $siteRoot = '') : void{
        $this->siteRoot = $siteRoot;
    }

    /**
     * Checks for custom templates and returns the filepath if so. Otherwise returns the regular filepath.
     * @param string $tpl the filename of the template
     * @param string $type the type of template
     * @return string The filepath of the template passed
     */
    function getFilepath(string $tpl, string $type = ''): string
    {
        if ($type === 'body') {
            if (file_exists(__DIR__ . "/../templates/email/custom_override/{$tpl}")) {
                return "custom_override/{$tpl}";
            } else if (preg_match('/CustomEvent_/', $tpl)) {
                return "base_templates/LEAF_template_body.tpl";
            } else {
                return "{$tpl}";
            }
        } else if ($type === 'subject') {
            if (file_exists(__DIR__ . "/../templates/email/custom_override/{$tpl}")) {
                return "custom_override/{$tpl}";
            } else if (preg_match('/CustomEvent_/', $tpl)) {
                return "base_templates/LEAF_template_subject.tpl";
            } else {
                return "{$tpl}";
            }
        } else {
            if (file_exists(__DIR__ . "/../templates/email/custom_override/{$tpl}")) {
                return "custom_override/{$tpl}";
            } else {
                return "{$tpl}";
            }
        }
    }

    /**
     * Removes all email addresses from object recipient variable
     */
    public function clearRecipients(): void
    {
        $this->emailRecipient = '';
    }

    /**
     * Set email sender object variable
     * @param string|null $strAddress
     */
    public function setSender(string|null $strAddress): void
    {
        $this->emailSender = $strAddress;
    }

    /**
     * Clean and Set subject of email object variable
     * @param string $strSubject
     */
    public function setSubject(string $strSubject): void
    {
        $prefix = isset(Config::$emailPrefix) ? Config::$emailPrefix : 'Resources: ';
        $this->emailSubject = $prefix . strip_tags($strSubject);
    }

    /**
     * Add content into template variable then into template file
     * This result will then be added into the object variable as HTML output
     * @param string $strContent   - content to add to template
     * @param string $tplVar       - variable within template
     * @param string $tplFile      = template file name
     */
    public function setContent(string $tplFile, string $tplVar = '', string $strContent = ''): string
    {
        if($tplVar != '') {
            $strContent = str_replace("\r\n", '<br />', $strContent);
        }
        $smarty = new \Smarty;
        $smarty->template_dir = __DIR__ . '/../templates/email/';
        $smarty->compile_dir = __DIR__ . '/../templates_c/';
        $smarty->left_delimiter = '{{';
        $smarty->right_delimiter = '}}';
        if (($tplVar != '') && ($strContent != '')) {
            $smarty->assign($tplVar, $strContent);
        } else {
            $smarty->assign($this->smartyVariables);
        }
        $htmlOutput = $smarty->fetch($tplFile);
        return $htmlOutput;
    }

    /**
     * Purpose: To check that email address is not already attached to this email send
     * @param string|null $address
     * @return bool
     */
    public function emailActiveNotAlreadyAdded(string|null $address): bool
    {

        if ( ( strpos($this->emailRecipient, $address) === false  )
            && (!in_array($address, $this->emailCC) )
            && (!in_array($address ,$this->emailBCC) ) ) {

            $dir = new VAMC_Directory;

            // Check that email address is active in Nexus
            $vars = array(':emailAddress' => $address);
            $strSQL = "SELECT e.deleted FROM employee as e ".
                "INNER JOIN employee_data ed on e.empUID = ed.empUID ".
                "WHERE e.deleted = 0 ".
                "AND ed.data=:emailAddress";
            $res = $this->nexus_db->prepared_query($strSQL, $vars);

            return ( (!empty($res)) ? true : false );
        }
        return false;
    }

    /**
     * Purpose: Add Receipient to email
     * @param string|null $address
     * @param bool $requiredAddress
     * @return bool
     */
    public function addRecipient(string|null $address, bool $requiredAddress = false): bool
    {
        if (preg_match('/(\w+@[a-zA-Z_)+?\.[a-zA-Z]{2,6})/', $address) == 0){
            return false;
        }

        if ($this->emailRecipient == ''){
            $this->emailRecipient = $address;
        } else {
            if ( $this->emailActiveNotAlreadyAdded($address) || $requiredAddress ) {
                $this->emailRecipient .= ", " . $address;
            }
        }

        // Returning true because either added here or already added
        return true;
    }

    /**
     * Adds all users in a given Position to the receipient object variable list
     * @param int $positionID
     */
    public function addPositionRecipient(int $positionID): void
    {
        if ($this->orgchartInitialized == false)
        {
            $this->initOrgchart();
        }
        $employees = $this->position->getEmployees($positionID);
        foreach ($employees as $emp) {
            $res = $this->employee->getAllData($emp['empUID'], 6);
            $this->addRecipient($res[6]['data']);
        }
    }

    /**
     * Adds all users in a given Group to the reeeipient object variable list
     * @param int $groupID
     */
    public function addGroupRecipient(int $groupID): void
    {
        $dir = new VAMC_Directory;

        $vars = array(':groupID' => $groupID);
        $strSQL = "SELECT `userID` FROM `users` ".
            "WHERE groupID=:groupID ".
            "AND active=1";
        $res = $this->portal_db->prepared_query($strSQL, $vars);

        foreach($res as $user) {
            $tmp = $dir->lookupLogin($user['userID']);
            if (isset($tmp[0]['Email']) && $tmp[0]['Email'] != '') {
                $this->addRecipient($tmp[0]['Email']);
            }
        }
    }

    /**
     * Scrubs email address and adds to object email CC array if valid
     * @param string|null $strEmailAddress
     * @param bool $requiredAddress
     * @param bool $isBcc
     * @return bool
     */

    public function addCcBcc(string|null $address, bool $requiredAddress = false, bool $isBcc = false): bool
    {
        if (preg_match('/(\w+@[a-zA-Z_)+?\.[a-zA-Z]{2,6})/', $address) == 0) {
            return false;
        }

        if ( $this->emailActiveNotAlreadyAdded($address) || ($requiredAddress)  ) {
          if (!$isBcc) {
              $this->emailCC[] = $address;
          } else {
              $this->emailBCC[] = $address;
          }
        }

        return true;
    }

    /**
     * Assign email variables to email send and perform Send
     * Will throw exception if Send not completed and then return false
     * @return bool
     * @throws Exception
     */
    public function sendMail(?int $recordID = null): bool
    {
        $currDir = dirname(__FILE__);

        if (isset(Config::$emailCC) && count(Config::$emailCC) > 0) {
            foreach (Config::$emailCC as $recipient) {
                $this->addCcBcc($recipient);
            }
        }

        if (isset(Config::$emailBCC) && count(Config::$emailBCC) > 0) {
            foreach (Config::$emailBCC as $recipient) {
                $this->addCcBcc($recipient, false,true);
            }
        }
        $email['recipient'] = html_entity_decode($this->emailRecipient, ENT_QUOTES);
        $email['subject'] = $this->emailSubject;
        $email['body'] = $this->emailBody;
        $email['headers'] = html_entity_decode($this->getHeaders(), ENT_QUOTES);

        $emailCache = serialize($email);
        $emailQueueName = sha1($emailCache . random_int(0, 99999999));
        if (strlen(trim($emailCache)) == 0) {
            trigger_error('Mail error: ' . $this->emailSubject);
            return false;
        }

        // if we have no recipients then we should not create the email.
        if(strlen($email['recipient']) == 0) {
            trigger_error('Mail error: No Recipients: ' . $this->emailSubject);
            return false;
        }

        file_put_contents($currDir . '/../templates_c/mailer/' . $emailQueueName, $emailCache);

        if (strtoupper(substr(php_uname('s'), 0, 3)) == 'WIN') {
            $shell = new \COM('WScript.Shell');
            $shell->Run("php {$currDir}/../mailer/mailer.php {$emailQueueName}", 0, false);
        } else {
            exec("php {$currDir}/../mailer/mailer.php {$emailQueueName} > /dev/null &");
        }

        if ($recordID !== null) {
            $this->logEmailSent($recordID);
        }

        return true;
    }

    /**
     * @return void
     *
     * Created at: 5/11/2023, 12:13:40 PM (America/New_York)
     */
    private function logEmailSent(int $recordID): void
    {
        $email_tracker = new EmailTracker($this->portal_db);
        $email_tracker->postEmailTracker($recordID, 'Recipient(s): ' . $this->emailRecipient, 'Subject: ' . $this->emailSubject);
    }

    /**
     * Gets current user's employeeID, positionID, groupID
     * and assigns them to email object variables
     */
    private function initOrgchart(): void
    {
        // set up org chart assets
        $oc_db = new \Leaf\Db(\DIRECTORY_HOST, \DIRECTORY_USER, \DIRECTORY_PASS, \ORGCHART_DB);
        $oc_login = new \Orgchart\Login($oc_db, $oc_db);
        $oc_login->loginUser();
        $this->employee = new \Orgchart\Employee($oc_db, $oc_login);
        $this->position = new \Orgchart\Position($oc_db, $oc_login);
        $this->group = new \Orgchart\Group($oc_db, $oc_login);
        $this->orgchartInitialized = true;
    }

    /**
     * Initialize portal db object
     * @return void
     */
    function initPortalDB(): void
    {
        // set up org chart assets
        $db_config = new DbConfig;
        $this->portal_db = new \Leaf\Db($db_config->dbHost, $db_config->dbUser, $db_config->dbPass, $db_config->dbName);
    }

    /**
     * Initialize Nexus db object
     * @return void
     */
    function initNexusDB(): void
    {
        // set up org chart assets
        $this->nexus_db = new \Leaf\Db(\DIRECTORY_HOST, \DIRECTORY_USER, \DIRECTORY_PASS, \ORGCHART_DB);
    }

    /**
     * Generates email headers
     * @return string
     */
    private function getHeaders(): string
    {
        $header = 'MIME-Version: 1.0';
        $header .= "\r\nContent-type: text/html; charset=iso-8859-1";
        if ($this->emailSender == '') {
            $header .= "\r\nFrom: {$this->emailFrom}";
        } else {
            $header .= "\r\nSender: {$this->emailFrom}";
            $header .= "\r\nFrom: {$this->emailSender}";
            $header .= "\r\nReply-To: {$this->emailSender}";
        }

        if (count($this->emailCC) > 0) {
            $header .= "\r\nCc: ";
            foreach ($this->emailCC as $cc) {
                $header .= "$cc, ";
            }
            $header = rtrim($header, ', ');
        }

        if (count($this->emailBCC) > 0) {
            $header .= "\r\nBcc: ";
            foreach ($this->emailBCC as $bcc) {
                $header .= "$bcc, ";
            }
            $header = rtrim($header, ', ');
        }

        return $header;
    }

    /**
     * Gets templated ID by label name
     * @param string $emailTemplateLabel email template name
     * @return int Email template ID number
     */
    function getTemplateIDByLabel(string $emailTemplateLabel): int
    {
        $vars = array(':emailTemplateLabel' => $emailTemplateLabel);
        $strSQL = "SELECT `emailTemplateID` FROM `email_templates` ".
            "WHERE label = :emailTemplateLabel;";
        $res = $this->portal_db->prepared_query($strSQL, $vars);

        return (int)$res[0]['emailTemplateID'];
    }

    /**
     * Gets template filenames from the db based on emailTemplateID and sets the properties
     * @param int $emailTemplateID emailTemplateID from email_templates table
     * @return void
     */
    function setTemplateByID(int $emailTemplateID): void
    {
        $vars = array(':emailTemplateID' => $emailTemplateID);
        $strSQL = "SELECT `emailTo`, `emailCc`,`subject`, `body` FROM `email_templates` ".
            "WHERE emailTemplateID = :emailTemplateID;";
        $res = $this->portal_db->prepared_query($strSQL, $vars);

        $this->setEmailToCcWithTemplate(\Leaf\XSSHelpers::xscrub($res[0]['emailTo']));
        $this->setEmailToCcWithTemplate(\Leaf\XSSHelpers::xscrub($res[0]['emailCc']), true);
        $this->setSubjectWithTemplate(\Leaf\XSSHelpers::xscrub($res[0]['subject']));
        $this->setBodyWithTemplate(\Leaf\XSSHelpers::xscrub($res[0]['body']));
    }

    /**
     * Gets template filenames from the db based on label and sets the properties
     * @param string $emailTemplateLabel label from email_templates table
     * @return void
     */
    function setTemplateByLabel(string $emailTemplateLabel): void
    {
        $vars = array(':emailTemplateLabel' => $emailTemplateLabel);
        $strSQL = "SELECT `emailTo`,`emailCc`,`subject`, `body` FROM `email_templates` ".
            "WHERE label = :emailTemplateLabel;";
        $res = $this->portal_db->prepared_query($strSQL, $vars);

        $this->setEmailToCcWithTemplate(\Leaf\XSSHelpers::xscrub($res[0]['emailTo']));
        $this->setEmailToCcWithTemplate(\Leaf\XSSHelpers::xscrub($res[0]['emailCc']), true);
        $this->setSubjectWithTemplate(\Leaf\XSSHelpers::xscrub($res[0]['subject']));
        $this->setBodyWithTemplate(\Leaf\XSSHelpers::xscrub($res[0]['body']));
    }

    /**
     * Given email template location where email addresses are stored
     * Get the email addresses, line by line, and add them if valid to CC or BCC
     * @param string $tplLocation
     * @param bool $isCc
     * @param false $isBcc
     */
    function setEmailToCcWithTemplate(string $tplLocation, bool $isCc = false): void
    {
        // Determine if template currently has any email addresses saved
        $tplLocation = str_replace(array('email_to', 'email_cc'), array('emailTo', 'emailCC'), $tplLocation);
        $hasEmailTemplate = $this->getFilepath($tplLocation);
        $emailTemplate = __DIR__ . '/../templates/email/' . $hasEmailTemplate;
        if (file_exists($emailTemplate)) {
            $emailList = file($emailTemplate, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES );
            // For each line in template, add that email address, if valid
            foreach($emailList as $emailAddress) {
                if ($isCc) {
                    $this->addCcBcc(\Leaf\XSSHelpers::xscrub($emailAddress), true);
                } else {
                    $this->addRecipient(\Leaf\XSSHelpers::xscrub($emailAddress), true);
                }
            }
        }

    }

    /**
     * Sets the subject based on the given smarty template
     * @param string $subjectTemplate the filename of the template for the subject
     * @return void
     */
    function setSubjectWithTemplate(string $subjectTemplate): void
    {
        $htmlOutput = $this->setContent($this->getFilepath($subjectTemplate, 'subject'));
        $this->setSubject($htmlOutput);
    }

    /**
     * Purpose (deprecated): set email body directly from passed in HTML
     * LEGACY: Included as scripts created by portal uses that implement sends using this feature
     * @param string $i
     * @throws SmartyException
     */
    public function setBody(string $i): void
    {
        $i = str_replace("\r\n", '<br />', $i);
        $smarty = new \Smarty;
        $smarty->template_dir = __DIR__ . '/../templates/email/';
        $smarty->compile_dir = __DIR__ . '/../templates_c/';
        $smarty->left_delimiter = '{{';
        $smarty->right_delimiter = '}}';
        $smarty->assign('emailBody', $i);
        $htmlOutput = $smarty->fetch('LEAF_main_email_template.tpl');
        $this->emailBody = $htmlOutput;
    }

    /**
     * Sets the body based on the given smarty template
     * @param string $bodyTemplate the filename of the template for the body
     * @return void
     */
    function setBodyWithTemplate(string $bodyTemplate): void
    {
        $htmlOutput = $this->setContent($this->getFilepath($bodyTemplate, 'body'));
        $this->emailBody = $this->setContent(
            'LEAF_main_email_template.tpl',
            'emailBody',
            $htmlOutput
        );
    }

    /**
     * Performs array_merge on the current smartyVariables, adding the passed in variables.
     * If there are any repeated keys, the new values will override the old
     * @param array $newVariables associative array where the keys are the variable names and the values are the variable values
     * @return void
     */
    function addSmartyVariables(array $newVariables): void
    {
        $this->smartyVariables = array_merge($this->smartyVariables, $newVariables);
    }

    /**
     * Purpose: Add approvers to email from given record ID*
     * @param int $recordID
     * @param int $emailTemplateID
     * @param mixed $loggedInUser
     * @throws Exception
     */
    function attachApproversAndEmail(int $recordID, int $emailTemplateID, mixed $loggedInUser): bool
    {
        // Lookup approvers of current record so we can notify
        $vars = array(':recordID' => $recordID);
        $strSQL = "SELECT users.userID AS approverID, sd.dependencyID, sd.stepID, ser.serviceID, ser.service, ser.groupID AS quadrad, users.groupID, rec.title, rec.lastStatus FROM records_workflow_state ".
            "LEFT JOIN records AS rec USING (recordID) ".
            "LEFT JOIN step_dependencies AS sd USING (stepID) ".
            "LEFT JOIN dependency_privs USING (dependencyID) ".
            "LEFT JOIN users USING (groupID) ".
            "LEFT JOIN services AS ser USING (serviceID) ".
            "WHERE recordID=:recordID AND (active=1 OR active IS NULL)";
        $approvers = $this->portal_db->prepared_query($strSQL, $vars);

        // Start adding users to email if we have them
        if (count($approvers) > 0) {
            $title = strlen($approvers[0]['title']) > 45 ? substr($approvers[0]['title'], 0, 42) . '...' : $approvers[0]['title'];

            $this->addSmartyVariables(array(
                "truncatedTitle" => $title,
                "fullTitle" => $approvers[0]['title'],
                "recordID" => $recordID,
                "service" => $approvers[0]['service'],
                "lastStatus" => $approvers[0]['lastStatus'],
                "siteRoot" => $this->siteRoot
            ));

            if ($emailTemplateID < 2) {
                $this->setTemplateByID($emailTemplateID);
            }

            $dir = new VAMC_Directory;

            foreach ($approvers as $approver) {
                if (strlen($approver['approverID']) > 0) {
                    $tmp = $dir->lookupLogin($approver['approverID']);
                    if (isset($tmp[0]['Email']) && $tmp[0]['Email'] != '') {
                        $this->addRecipient($tmp[0]['Email']);
                    }
                }

                // Special cases depending on dependency of record
                switch ($approver['dependencyID']) {
                    // special case for service chiefs
                    case 1:
                        $vars = array(':serviceID' => $approver['serviceID']);
                        $strSQL = "SELECT userID FROM service_chiefs WHERE serviceID=:serviceID AND active=1";
                        $chief = $this->portal_db->prepared_query($strSQL, $vars);

                        foreach ($chief as $member) {
                            if (strlen($member['userID']) > 0) {
                                $tmp = $dir->lookupLogin($member['userID']);
                                if (isset($tmp[0]['Email']) && $tmp[0]['Email'] != '') {
                                    $this->addRecipient($tmp[0]['Email']);
                                }
                            }
                        }
                        break;

                    // special case for quadrads
                    case 8:
                        $vars = array(':groupID' => $approver['quadrad']);
                        $strSQL = "SELECT userID FROM users WHERE groupID=:groupID AND active=1";
                        $quadrad = $this->portal_db->prepared_query($strSQL, $vars);
                        foreach ($quadrad as $member) {
                            if (strlen($member['userID']) > 0) {
                                $tmp = $dir->lookupLogin($member['userID']);
                                if (isset($tmp[0]['Email']) && $tmp[0]['Email'] != '') {
                                    $this->addRecipient($tmp[0]['Email']);
                                }
                            }
                        }
                        break;

                    // special case for a person designated by the requestor
                    case -1:
                        $form = new Form($this->portal_db, $loggedInUser);

                        // find the next step
                        $varsStep = array(':stepID' => $approver['stepID']);
                        $strSQL = "SELECT indicatorID_for_assigned_empUID FROM workflow_steps WHERE stepID=:stepID";
                        $resStep = $this->portal_db->prepared_query($strSQL, $varsStep);

                        $resEmpUID = $form->getIndicator($resStep[0]['indicatorID_for_assigned_empUID'], 1, $recordID);
                        $empUID = $resEmpUID[$resStep[0]['indicatorID_for_assigned_empUID']]['value'];

                        //check if the requester has any backups
                        $vars4 = array(':empId' => $empUID);
                        $strSQL = "SELECT backupEmpUID FROM relation_employee_backup WHERE empUID =:empId";
                        $backupIds = $this->nexus_db->prepared_query($strSQL, $vars4);

                        if ($empUID > 0) {
                            $tmp = $dir->lookupEmpUID($empUID);
                            if (isset($tmp[0]['Email']) && $tmp[0]['Email'] != '') {
                                $this->addRecipient($tmp[0]['Email']);
                            }
                        }

                        // add for backups
                        foreach ($backupIds as $row) {
                            $tmp = $dir->lookupEmpUID($row['backupEmpUID']);
                            if (isset($tmp[0]['Email']) && $tmp[0]['Email'] != '') {
                                $this->addCcBcc($tmp[0]['Email']);
                            }
                        }
                        break;

                    // requestor followup
                    case -2:
                        $vars = array(':recordID' => $recordID);
                        $strSQL = "SELECT userID FROM records WHERE recordID=:recordID";
                        $resRequestor = $this->portal_db->prepared_query($strSQL, $vars);
                        $tmp = $dir->lookupLogin($resRequestor[0]['userID']);
                        if (isset($tmp[0]['Email']) && $tmp[0]['Email'] != '') {
                            $this->addRecipient($tmp[0]['Email']);
                        }
                        break;

                    // special case for a group designated by the requestor
                    case -3:
                        $form = new Form($this->portal_db, $loggedInUser);

                        // find the next step
                        $varsStep = array(':stepID' => $approver['stepID']);
                        $strSQL = "SELECT indicatorID_for_assigned_groupID FROM workflow_steps WHERE stepID=:stepID";
                        $resStep = $this->portal_db->prepared_query($strSQL, $varsStep);

                        $resGroupID = $form->getIndicator($resStep[0]['indicatorID_for_assigned_groupID'], 1, $recordID);
                        $groupID = $resGroupID[$resStep[0]['indicatorID_for_assigned_groupID']]['value'];

                        if ($groupID > 0) {
                            $this->addGroupRecipient($groupID);
                        }
                        break;
                }
            }
            $return_value = $this->sendMail($recordID);
        } elseif ($emailTemplateID === -4) {
            // Record has no approver so if it is sent from Mass Action Email Reminder, notify user
            $vars = array(':recordID' => $recordID);
            $strSQL =  "SELECT rec.userID, rec.serviceID, ser.service, rec.title,
                            rec.lastStatus
                        FROM records AS rec
                        LEFT JOIN services AS ser USING (serviceID)
                        WHERE recordID=:recordID";

            $recordInfo = $this->portal_db->prepared_query($strSQL, $vars);

            $title = strlen($recordInfo[0]['title']) > 45 ? substr($recordInfo[0]['title'], 0, 42) . '...' : $recordInfo[0]['title'];

            $this->addSmartyVariables(array(
                "truncatedTitle" => $title,
                "fullTitle" => $recordInfo[0]['title'],
                "recordID" => $recordID,
                "service" => $recordInfo[0]['service'],
                "lastStatus" => $recordInfo[0]['lastStatus'],
                "siteRoot" => $this->siteRoot
            ));

            $this->setTemplateByID($emailTemplateID);

            $dir = new VAMC_Directory;

            // Get user email and send
            $tmp = $dir->lookupLogin($recordInfo[0]['userID']);
            if (isset($tmp[0]['Email']) && $tmp[0]['Email'] != '') {
                $this->addRecipient($tmp[0]['Email']);
            }
            $return_value = $this->sendMail($recordID);
        } elseif ($emailTemplateID > 1) {
            $return_value = $this->sendMail($recordID); // Check for custom event to finalize email on Notify Next
        }

        return $return_value;
    }
}
