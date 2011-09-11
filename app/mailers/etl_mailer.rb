class EtlMailer < ActionMailer::Base
  default :from => 'admin@datanest.sk'
  
  def vvo_loading_status(records_with_error, records_with_note)
    @records_with_error, @records_with_note = records_with_error, records_with_note
    mail(:to => 'kunder@fair-play.sk, eva@fair-play.sk, olahmichal@gmail.com', :subject => "Vysledok automatickeho behu ETL.")
  end
end
