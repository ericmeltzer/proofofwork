class InvitationMailer < ActionMailer::Base
  default :from => "Proofofwork <pow@primitive.ventures>"

  def invitation(invitation)

    @invitation = invitation
logger.info "========== invitation: " 
    mail(
      to: invitation.email,
      subject: "[Proof of Work] You are invited to join " <<
               "Proof of Work"
    )
  end
end
