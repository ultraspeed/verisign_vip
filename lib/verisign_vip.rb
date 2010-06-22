require 'rubygems'
require 'savon'
require 'uuidtools'
require 'hpricot'
require 'yaml'

class VerisignVIP
  class << self    
    # Use the ActivateToken API to activate new or 
    # inactive credentials. If the activation is 
    # successful, the credential is Enabled and 
    # ready for use.
    def activate_token(token_id, otp1 = nil, otp2 = nil)
      attributes  = "<wsdl:TokenId>#{token_id}</wsdl:TokenId>"
      attributes += "<wsdl:OTP1>#{otp1}</wsdl:OTP1>" if otp1
      attributes += "<wsdl:OTP2>#{otp2}</wsdl:OTP2>" if otp2
      
      soap_request(:mgmt, "ActivateToken", attributes)
    end
    
    # Use the DeactivateToken API to deactivate 
    # credentials. If you no longer want to allow 
    # a credential to be used on your Web site, 
    # you can deactivate the credential by 
    # setting it to the Inactive state.
    # 
    # When you deactivate a token, you can also 
    # specify the reason you deactivated. This 
    # information will be used as part to provide 
    # network wide intelligence information for 
    # the token.
    def deactivate_token(token_id, reason = nil)
      attributes  = "<wsdl:TokenId>#{token_id}</wsdl:TokenId>"
      attributes += "<wsdl:Reason>#{reason}</wsdl:Reason>" if reason
      
      soap_request(:mgmt, "DeactivateToken", attributes)
    end
    
    # Use the Validate API to authenticate credentials. 
    # To authenticate an Enabled credential, send a 
    # Validate call including the credential ID and a 
    # security code. Credentials are validated according 
    # to the security profile for that credential type. 
    # The Validate API can also be used to validate 
    # temporary security codes.
    #
    # When you send a Validate call, the VIP Web 
    # Services check the validity of the security code 
    # and return a response.
    def validate(token_id, otp)
      attributes  = "<wsdl:TokenId>#{token_id}</wsdl:TokenId>"
      attributes += "<wsdl:OTP>#{otp}</wsdl:OTP>"
      
      soap_request(:val, "Validate", attributes)
    end
    
    # Use the ValidateMultiple API to validate one of 
    # several credentials. To authenticate a user 
    # that has more than one credential, send a 
    # ValidateMultiple API call to check all of the 
    # user’s credentials against a single 
    # security code.
    def validate_multiple(token_ids, otp, send_successful_token_id = false)
      raise "An array of token IDs is required" unless token_ids.is_a?(Array)

      attributes = ""
      
      token_ids.each do |token|
        attributes += "<wsdl:TokenId>#{token}</wsdl:TokenId>"
      end
      
      attributes += "<wsdl:OTP>#{otp}</wsdl:OTP>"
      attributes += "<wsdl:SendSuccessfulTokenId>#{send_successful_token_id}</wsdl:SendSuccessfulTokenId>"

      soap_request(:val, "ValidateMultiple", attributes)
    end
    
    # When a user does not use their credential 
    # for an extended period of time, the credential 
    # becomes out of synchronization. Synchronization 
    # with VIP restores the credential’s synchronization.
    #
    # The Synchronize API restores a credential to 
    # synchronization. To synchronize an end user 
    # credential that is out of synchronization, send 
    # a synchronize call that includes the credential 
    # ID and two consecutive security codes. When you 
    # send a synchronize call, the VIP Web Services 
    # check the validity of the security codes, and 
    # return a response.
    #
    # Note: SMS credentials do not need to be 
    # synchronized.
    def synchronize(token_id, otp1, otp2)
      attributes  = "<wsdl:TokenId>#{token_id}</wsdl:TokenId>"
      attributes += "<wsdl:OTP1>#{otp1}</wsdl:OTP1>"
      attributes += "<wsdl:OTP2>#{otp2}</wsdl:OTP2>"
        
      soap_request(:val, "Synchronize", attributes)
    end
    
    # Credentials become locked when they exceed 
    # the configured number of allowed 
    # continuous validation failures.
    #
    # Use the UnlockToken API to unlock credentials 
    # that have become locked. Unlocking a 
    # credential changes the state of the 
    # credential from Locked to Enabled and makes 
    # it ready for use.
    #
    # Note: Verify that a user is in possession of 
    # their credential before you unlock it. First, 
    # verify the user’s identity through some other 
    # means, and then request a security code from 
    # the user. To check the security code, use the 
    # CheckOTP API. If the CheckOTP call succeeds, 
    # then make an UnlockToken call.
    def unlock_token(token_id)
      attributes = "<wsdl:TokenId>#{token_id}</wsdl:TokenId>"

      soap_request(:mgmt, "UnlockToken", attributes)
    end
    
    # Use the DisableToken API to disable a credential. 
    # Disabling a credential changes its state from 
    # Enabled or Locked to Disabled, and makes it 
    # unavailable for use. For example, an issuer 
    # should disable a credential if an end-user reports 
    # that the credential has been forgotten, 
    # lost, or stolen.
    #
    # When you disable a token, you can also specify 
    # the reason you disabled it. This information will 
    # be used as part to provide network wide 
    # intelligence information for the token.
    def disable_token(token_id, reason = nil)
      attributes  = "<wsdl:TokenId>#{token_id}</wsdl:TokenId>"
      attributes += "<wsdl:Reason>#{reason}</wsdl:Reason>" if reason

      soap_request(:mgmt, "DisableToken", attributes)
    end
    
    # Credentials can not be used, tested, or synchronized 
    # unless they are Enabled.
    # 
    # Use the EnableToken API to enable credentials that 
    # an issuer has disabled.
    #
    # Use this operation to change the state of a disabled 
    # credential to Enabled. When you Enable a credential, 
    # VIP Web Services check the validity of the credential 
    # ID and return a response. If the enable operation is 
    # successful, the credential changes from Disabled to 
    # Enabled and is ready for use.
    def enable_token(token_id)
      attributes = "<wsdl:TokenId>#{token_id}</wsdl:TokenId>"
      
      soap_request(:mgmt, "EnableToken", attributes)
    end
    
    # Use the SetTemporaryPassword API to set a temporary 
    # security code for a credential. You can optionally 
    # set an expiration date for the security code, or 
    # set it for one-time use only. The request requires 
    # the credential ID and the temporary security code 
    # string.
    #
    # You can also use the SetTemporaryPassword API to 
    # clear a temporary security code. To clear the 
    # temporary security code, send the 
    # SetTemporaryPassword API and leave the 
    # TemporaryPassword request parameter empty.
    #
    # Note: The SetTemporaryPassword API works on both 
    # Disabled and Enabled credentials. VeriSign 
    # recommends that you check the credential state 
    # before issuing a temporary security code. This 
    # prevents users from trying to authenticate using 
    # disabled credentials.
    def set_temporary_password(token_id, temporary_password, expiration_date = nil, one_time_use_only = nil)
      raise "expiration_date must be a Ruby Time object" if expiration_date and !expiration_date.is_a?(Time)
      raise "one_time_use_only must be either true or false" if one_time_use_only && ![true, false].include?(one_time_use_only)

      attributes  = "<wsdl:TokenId>#{token_id}</wsdl:TokenId>"
      attributes += "<wsdl:TemporaryPassword>#{temporary_password}</wsdl:TemporaryPassword>"
      attributes += "<wsdl:ExpirationDate>#{expiration_date.iso8601}</wsdl:ExpirationDate>" if expiration_date
      attributes += "<wsdl:OneTimeUseOnly>#{one_time_use_only}</wsdl:OneTimeUseOnly>" if one_time_use_only

      soap_request(:mgmt, "SetTemporaryPassword", attributes)
    end
    
    # Use the GenerateTemporaryPassword API to generate a 
    # temporary security code for a credential. You 
    # can optionally set an expiration date for the 
    # security code, or set it for one-time use only. 
    # The request requires the credential ID.
    #
    # Note: The GenerateTemporaryPassword API works on 
    # both Disabled and Enabled credentials. VeriSign 
    # recommends that you check the credential state 
    # before issuing a temporary security code. This 
    # prevents users from trying to authenticate 
    # using disabled credentials.
    def generate_temporary_password(token_id, expiration_date = nil, one_time_use_only = nil)
      raise "expiration_date must be a Ruby Time object" if expiration_date and !expiration_date.is_a?(Time)
      raise "one_time_use_only must be either true or false" if one_time_use_only && ![true, false].include?(one_time_use_only)
      
      attributes  = "<wsdl:TokenId>#{token_id}</wsdl:TokenId>"
      attributes += "<wsdl:ExpirationDate>#{expiration_date.iso8601}</wsdl:ExpirationDate>" if expiration_date
      attributes += "<wsdl:OneTimeUseOnly>#{one_time_use_only}</wsdl:OneTimeUseOnly>" if one_time_use_only
      
      soap_request(:mgmt, "GenerateTemporaryPassword", attributes)
    end
    
    # Use the SetTemporaryPwdExpiration API to change 
    # the expiration date for a temporary security 
    # code you previously set using the 
    # SetTemporaryPwdExpiration API.
    def set_temporary_pwd_expiration(token_id, expiration_date = nil)
      raise "expiration_date must be a Ruby Time object" if expiration_date and !expiration_date.is_a?(Time)

      attributes  = "<wsdl:TokenId>#{token_id}</wsdl:TokenId>"
      attributes += "<wsdl:ExpirationDate>#{expiration_date.iso8601}</wsdl:ExpirationDate>" if expiration_date

      soap_request(:mgmt, "SetTemporaryPwdExpiration", attributes)
    end
    
    # Use the GetTemporaryPwdExpiration API to find 
    # out the expiration date for a credential for 
    # which a temporary security code is already set.
    def get_temporary_pwd_expiration(token_id)
      attributes = "<wsdl:TokenId>#{token_id}</wsdl:TokenId>"
        
      soap_request(:mgmt, "GetTemporaryPwdExpiration", attributes)
    end
    
    # Use the CheckOTP API to validate or synchronize a 
    # credential even if the credential is locked.
    # 
    # The CheckOTP API validates or synchronizes a 
    # credential based on the number of security codes 
    # you provide. If you provide one security code, 
    # CheckOTP validates the credential. If you provide 
    # two security codes, CheckOTP synchronizes the credential.
    #
    # If a CheckOTP call fails to validate a credential, 
    # the CheckOTP call does not increment the credential's 
    # failed validation count. If a CheckOTP call synchronizes 
    # a credential, it does not change the credential state. 
    # You cannot use the CheckOTP API for credentials in a 
    # new or inactive state.
    #
    # Note: TheCheckOTP API call is for administrative 
    # purposes only, and is not a substitute for the 
    # Validate and Synchronize APIs.
    #
    # Do not use the CheckOTP API for normal authentication 
    # and synchronization because it overrides the 
    # requirement (in the Validate and Synchronize APIs) 
    # that a credential is Enabled.
    # 
    # Because CheckOTP authenticates and synchronizes 
    # locked credentials, VeriSign recommends that you 
    # use it only when you can verify the identity of 
    # an end user. For normal authentication and 
    # synchronization, use the Validate and 
    # Synchronize APIs.
    def check_otp(token_id, otp1, otp2 = nil)
      attributes  = "<wsdl:TokenId>#{token_id}</wsdl:TokenId>"
      attributes += "<wsdl:OTP1>#{otp1}</wsdl:OTP1>"
      attributes += "<wsdl:OTP2>#{otp2}</wsdl:OTP2>" if otp2

      soap_request(:mgmt, "CheckOTP", attributes)
    end
    
    # Use the GetTokenInformation API to get detailed 
    # information about a credential, such as the 
    # credential state, whether it is a hardware or 
    # software credential, the credential expiration date, 
    # and the last time an API call was made to the VIP 
    # Web Services about the credential. The request 
    # requires only the credential ID.
    def get_token_information(token_id)
      attributes = "<wsdl:TokenId>#{token_id}</wsdl:TokenId>"

      soap_request(:mgmt, "GetTokenInformation", attributes)
    end
    
    def get_server_time
      soap_request(:prov, "GetServerTime")
    end
    
    private
    
    def configuration
      begin
        @configuration ||= YAML::load(File.open(Rails.root.join("config", "verisign.yml")))
      rescue Errno::ENOENT
        raise Errno::ENOENT, "You must create a file called 'verisign.yml' containing configuration options in your config/ directory. See the README for details."
      end 
    end
    
    def soap_request(endpoint, action, attributes = nil)
      host = configuration[Rails.env]["hostname"]
      client = Savon::Client.new("https://#{host}/#{endpoint}/soap")      
      
      client.request.http.ssl_client_auth(
        :cert         => OpenSSL::X509::Certificate.new(File.open(configuration[Rails.env]["certificate_file"])),
        :key          => OpenSSL::PKey::RSA.new(File.open(configuration[Rails.env]["private_key_file"]), configuration[Rails.env]["private_key_password"]),
        :ca_file      => "cacert.pem",
        :verify_mode  => OpenSSL::SSL::VERIFY_PEER
      )
      
      response = client.send("#{action}!") do |soap|
        soap.action     = action
        soap.input      = action, { :Version => "2.0", :Id => UUIDTools::UUID.timestamp_create.to_s }
        soap.namespace  = "http://www.verisign.com/2006/08/vipservice"
        soap.body       = attributes if attributes
      end
      
      parse_response(response.to_xml)
    end
    
    def parse_response(xml)
      Hpricot::XML(xml)
    end
  end
end