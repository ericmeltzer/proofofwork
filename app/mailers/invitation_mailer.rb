class InvitationMailer < ActionMailer::Base
  default :from => "Proofofwork <shanhua2011@gmail.com>"

  def invitation(invitation)

    @invitation = invitation
logger.info "========== invitation: " 
    mail(
      to: invitation.email,
      subject: "Proofofwork] You are invited to join " <<
               "Proofofwork"
    )
  end
end
